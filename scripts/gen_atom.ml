(* Generate an atom feed *)

let id = Uri.of_string "https://jon.recoil.org/atom.xml"
let title : Syndic.Atom.text_construct = Syndic.Atom.Text "Jon's blog"

let author =
  Syndic.Atom.author "Jon Ludlam" ~uri:(Uri.of_string "https://jon.recoil.org/")

let updated = Unix.gettimeofday () |> Ptime.of_float_s |> Option.get


let entry_of_mld odoc_file =
  let report_error during msg =
    Format.eprintf "Error processing file '%s' while %s: %s\n%!"
      (Fpath.to_string odoc_file)
      during msg;
    exit 1
  in
  let unit =
    match Odoc_odoc.Odoc_file.load odoc_file with
    | Ok f -> f
    | Error (`Msg m) -> report_error "loading file" m
  in
  let page =
    match unit.content with
    | Odoc_odoc.Odoc_file.Page_content page -> page
    | _ -> failwith "Can't handle non-pages"
  in
  let document = Odoc_document.Renderer.document_of_page ~syntax:OCaml page in
  let frontmatter = page.frontmatter.Odoc_model.Frontmatter.other_config in
  let published = try List.assoc "published" frontmatter with Not_found -> report_error "parsing frontmatter" "No published date found" in
  let title, content, url =
    match document with
    | Odoc_document.Types.Document.Source_page _ ->
        report_error "handling odocl file" "Source page not supported"
    | Odoc_document.Types.Document.Page p ->
        let first_heading =
          List.find_map
            (function
              | Odoc_document.Types.Item.Heading h -> Some h | _ -> None)
            p.preamble
        in
        let first_heading =
          match first_heading with
          | Some h -> h
          | None -> report_error "parsing title" "No heading found"
        in
        let title =
          List.filter_map
            (function
              | Odoc_document.Types.Inline.{ desc = Text t; _ } -> Some t
              | _ -> None)
            first_heading.title
        in
        let resolve = Odoc_html.Link.Current p.url in
        let config =
          Odoc_html.Config.v ~semantic_uris:false ~indent:false ~flat:false
            ~open_details:false ~as_json:false ~remap:[] ()
        in
        let url = Odoc_html.Generator.filepath p.url ~config in
        let url =
          Format.asprintf "https://jon.recoil.org/%s" (Fpath.to_string url)
        in
        let preamble =
          List.map
            (function
              | Odoc_document.Types.Item.Text bs ->
                let bs' = List.filter (function | { Odoc_document.Types.Block.desc = Source _; _ } -> false | _ -> true) bs in (* Get rid of meta *)
                Odoc_document.Types.Item.Text bs'
              | x -> x) p.preamble in
        let html = Odoc_html.Generator.items ~config ~resolve preamble in
        let content_fmt = Fmt.list (Tyxml.Html.pp_elt ()) in
        let content = Format.asprintf "%a" content_fmt html in
        let title = String.concat "" title in
        let content =
          Printf.sprintf "%s<p>Continue reading <a href=\"%s\">here</a></p>" content url in
        (title, content, url)
  in

  let published =
    try
      ISO8601.Permissive.date published
      |> Ptime.of_float_s
    with _ ->
      Format.eprintf "Error with '%s'" published;
      exit 1
  in

  Syndic.Atom.entry ~id:(Uri.of_string url) ~title:(Syndic.Atom.Html (None, title))
    ~published:(Option.get published) ~updated:(Option.get published)
    ~summary:(Syndic.Atom.Text "Summary")
    ~content:(Syndic.Atom.Html (None, content))
    ~links:[ Syndic.Atom.link ~rel:Syndic.Atom.Self (Uri.of_string url) ]
    ~authors:(author, []) ()

let entries =
  let mlds =
    Bos.OS.Dir.fold_contents
      (fun path acc ->
        if
          Fpath.basename path <> "page-index.odocl"
          && Fpath.has_ext "odocl" path
        then path :: acc
        else acc)
      []
      (Fpath.v "_tmp/_odoc/blog")
  in
  match mlds with
  | Ok mlds -> List.map entry_of_mld mlds
  | Error (`Msg m) ->
      Format.eprintf "Error finding blog posts: %s\n%!" m;
      []

let self_link =
  Syndic.Atom.link ~rel:Self (Uri.of_string "https://jon.recoil.org/atom.xml")

let feed = Syndic.Atom.feed ~id ~title ~updated ~links:[ self_link ] entries
let _ = Syndic.Atom.write feed "atom.xml"
