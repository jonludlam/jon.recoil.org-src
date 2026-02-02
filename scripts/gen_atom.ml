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
    None
  in
  let unit =
    match Odoc_odoc.Odoc_file.load odoc_file with
    | Ok f -> Some f
    | Error (`Msg m) ->
        ignore (report_error "loading file" m);
        None
  in
  match unit with
  | None -> None
  | Some unit -> (
      let page =
        match unit.content with
        | Odoc_odoc.Odoc_file.Page_content page -> Some page
        | _ -> None
      in
      match page with
      | None -> None
      | Some page -> (
          let document =
            Odoc_document.Renderer.document_of_page ~syntax:OCaml page
          in
          let frontmatter = page.frontmatter.Odoc_model.Frontmatter.other_config in
          let published =
            try Some (List.assoc "published" frontmatter) with Not_found -> None
          in
          match published with
          | None -> None (* Skip posts without published date *)
          | Some published -> (
              match document with
              | Odoc_document.Types.Document.Source_page _ -> None
              | Odoc_document.Types.Document.Page p ->
                  let first_heading =
                    List.find_map
                      (function
                        | Odoc_document.Types.Item.Heading h -> Some h
                        | _ -> None)
                      p.preamble
                  in
                  match first_heading with
                  | None ->
                      ignore (report_error "parsing title" "No heading found");
                      None
                  | Some first_heading ->
                  let title =
                    List.filter_map
                      (function
                        | Odoc_document.Types.Inline.{ desc = Text t; _ } -> Some t
                        | _ -> None)
                      first_heading.title
                  in
                  let title = String.concat "" title in
                  if title = "" then None
                  else
                    let resolve = Odoc_html.Link.Current p.url in
                    let config =
                      Odoc_html.Config.v ~semantic_uris:false ~indent:false
                        ~flat:false ~open_details:false ~as_json:false ~remap:[] ()
                    in
                    let url = Odoc_html.Generator.filepath p.url ~config in
                    let url =
                      Format.asprintf "https://jon.recoil.org/%s"
                        (Fpath.to_string url)
                    in
                    (* Generate full content: preamble + items *)
                    let all_items = p.preamble @ p.items in
                    let html = Odoc_html.Generator.items ~config ~resolve all_items in
                    let content_fmt = Fmt.list (Tyxml.Html.pp_elt ()) in
                    let content = Format.asprintf "%a" content_fmt html in
                    (* Extract first paragraph for summary *)
                    let summary =
                      let first_text =
                        List.find_map
                          (function
                            | Odoc_document.Types.Item.Text blocks ->
                                List.find_map
                                  (function
                                    | { Odoc_document.Types.Block.desc =
                                          Odoc_document.Types.Block.Paragraph inline;
                                        _
                                      } ->
                                        let text =
                                          List.filter_map
                                            (function
                                              | Odoc_document.Types.Inline.
                                                  { desc = Text t; _ } ->
                                                  Some t
                                              | _ -> None)
                                            inline
                                        in
                                        if text = [] then None
                                        else Some (String.concat "" text)
                                    | _ -> None)
                                  blocks
                            | _ -> None)
                          p.preamble
                      in
                      match first_text with
                      | Some t ->
                          if String.length t > 200 then
                            String.sub t 0 200 ^ "..."
                          else t
                      | None -> title
                    in
                    let published =
                      try
                        ISO8601.Permissive.date published |> Ptime.of_float_s
                      with _ ->
                        Format.eprintf "Error parsing date '%s' for %s\n%!"
                          published (Fpath.to_string odoc_file);
                        None
                    in
                    match published with
                    | None -> None
                    | Some published ->
                        Some
                          (Syndic.Atom.entry ~id:(Uri.of_string url)
                             ~title:(Syndic.Atom.Text title)
                             ~published ~updated:published
                             ~summary:(Syndic.Atom.Text summary)
                             ~content:(Syndic.Atom.Html (None, content))
                             ~links:
                               [
                                 Syndic.Atom.link ~rel:Syndic.Atom.Alternate
                                   (Uri.of_string url);
                               ]
                             ~authors:(author, []) ()))))

let is_blog_post path =
  let basename = Fpath.basename path in
  Fpath.has_ext "odocl" path
  && String.length basename > 5
  && String.sub basename 0 5 = "page-"
  && basename <> "page-index.odocl"

let entries =
  let mlds =
    Bos.OS.Dir.fold_contents
      (fun path acc -> if is_blog_post path then path :: acc else acc)
      []
      (Fpath.v "_tmp/_odoc/blog")
  in
  match mlds with
  | Ok mlds ->
      let entries = List.filter_map entry_of_mld mlds in
      (* Sort by published date, newest first *)
      List.sort Syndic.Atom.descending entries
  | Error (`Msg m) ->
      Format.eprintf "Error finding blog posts: %s\n%!" m;
      []

let self_link =
  Syndic.Atom.link ~rel:Self (Uri.of_string "https://jon.recoil.org/atom.xml")

let alt_link =
  Syndic.Atom.link ~rel:Alternate (Uri.of_string "https://jon.recoil.org/blog/")

let feed =
  Syndic.Atom.feed ~id ~title ~updated ~links:[ self_link; alt_link ] entries

let _ =
  Syndic.Atom.write feed "atom.xml";
  Format.printf "Generated atom.xml with %d entries\n%!" (List.length entries)
