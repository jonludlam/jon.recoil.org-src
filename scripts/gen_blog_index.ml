(* Generate blog index.mld files and recent entries list *)

let month_name = function
  | 1 -> "January" | 2 -> "February" | 3 -> "March" | 4 -> "April"
  | 5 -> "May" | 6 -> "June" | 7 -> "July" | 8 -> "August"
  | 9 -> "September" | 10 -> "October" | 11 -> "November" | 12 -> "December"
  | _ -> "Unknown"

type post = {
  year : int;
  month : int;
  slug : string;      (* e.g., "claude-and-dune" *)
  title : string;
  published : string; (* e.g., "2025-12-18" *)
}

let parse_post path =
  let ic = open_in path in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;

  (* Extract title from {0 ...} *)
  let title =
    let re = Str.regexp "{0 \\([^}]+\\)}" in
    if Str.string_match re content 0 then
      Str.matched_group 1 content
    else
      Filename.basename path |> Filename.remove_extension
  in

  (* Extract published date from @published ... *)
  let published =
    let re = Str.regexp "@published \\([0-9-]+\\)" in
    try
      ignore (Str.search_forward re content 0);
      Str.matched_group 1 content
    with Not_found -> ""
  in

  (* Parse path to get year/month/slug *)
  let parts = String.split_on_char '/' path in
  match parts with
  | _ :: year_s :: month_s :: filename :: [] ->
      let year = int_of_string year_s in
      let month = int_of_string month_s in
      let slug = Filename.remove_extension filename in
      Some { year; month; slug; title; published }
  | _ -> None

let find_posts () =
  let posts = ref [] in
  let rec scan_dir dir =
    let entries = Sys.readdir dir in
    Array.iter (fun entry ->
      let path = Filename.concat dir entry in
      if Sys.is_directory path then
        scan_dir path
      else if Filename.extension entry = ".mld" && entry <> "index.mld" then
        match parse_post path with
        | Some post when post.published <> "" -> posts := post :: !posts
        | _ -> ()
    ) entries
  in
  scan_dir "blog";
  (* Sort by published date descending *)
  List.sort (fun a b -> String.compare b.published a.published) !posts

let post_link post =
  let slug_needs_quotes =
    String.exists (fun c -> c = '-' || c = '_') post.slug
  in
  let slug_fmt =
    if slug_needs_quotes then
      Printf.sprintf "page-\"%s\"" post.slug
    else
      Printf.sprintf "page-%s" post.slug
  in
  Printf.sprintf "{{!/site/blog/%04d/%02d/%s}%s}"
    post.year post.month slug_fmt post.title

let generate_month_index year month posts =
  let month_posts = List.filter (fun p -> p.year = year && p.month = month) posts in
  if month_posts = [] then None
  else
    let children =
      month_posts
      |> List.map (fun p -> p.slug)
      |> String.concat " "
    in
    let content = Printf.sprintf "{0 %s}\n\n@children_order %s\n\n"
      (month_name month) children
    in
    Some content

let generate_year_index year posts =
  let year_posts = List.filter (fun p -> p.year = year) posts in
  if year_posts = [] then None
  else
    (* Get unique months, sorted descending *)
    let months =
      year_posts
      |> List.map (fun p -> p.month)
      |> List.sort_uniq (fun a b -> compare b a)
    in
    let children_order =
      months
      |> List.map (Printf.sprintf "%02d/")
      |> String.concat " "
    in
    let post_links =
      year_posts
      |> List.map (fun p -> "- " ^ post_link p)
      |> String.concat "\n"
    in
    let content = Printf.sprintf "{0 %d}\n\n@children_order %s\n\n%s\n"
      year children_order post_links
    in
    Some content

let generate_blog_index posts =
  (* Get unique years, sorted descending *)
  let years =
    posts
    |> List.map (fun p -> p.year)
    |> List.sort_uniq (fun a b -> compare b a)
  in
  let children_order =
    years
    |> List.map (fun y -> Printf.sprintf "%d/" y)
    |> String.concat " "
  in
  Printf.sprintf "{0 Blog}\n\n@children_order %s\n\nUse the sidebar to navigate the blog posts. The most recent posts are listed first.\n"
    children_order

let generate_recent_entries posts n =
  let recent =
    if List.length posts > n then
      List.filteri (fun i _ -> i < n) posts
    else
      posts
  in
  recent
  |> List.map (fun p -> "- " ^ post_link p)
  |> String.concat "\n"

let write_file path content =
  let oc = open_out path in
  output_string oc content;
  close_out oc;
  Printf.printf "Wrote %s\n" path

let () =
  let posts = find_posts () in
  Printf.printf "Found %d posts\n\n" (List.length posts);

  (* Get unique year/month combinations *)
  let year_months =
    posts
    |> List.map (fun p -> (p.year, p.month))
    |> List.sort_uniq compare
  in

  (* Generate month indexes *)
  List.iter (fun (year, month) ->
    match generate_month_index year month posts with
    | Some content ->
        let dir = Printf.sprintf "blog/%04d/%02d" year month in
        let path = Filename.concat dir "index.mld" in
        write_file path content
    | None -> ()
  ) year_months;

  (* Get unique years *)
  let years =
    posts
    |> List.map (fun p -> p.year)
    |> List.sort_uniq (fun a b -> compare b a)
  in

  (* Generate year indexes *)
  List.iter (fun year ->
    match generate_year_index year posts with
    | Some content ->
        let path = Printf.sprintf "blog/%04d/index.mld" year in
        write_file path content
    | None -> ()
  ) years;

  (* Generate main blog index *)
  let blog_index = generate_blog_index posts in
  write_file "blog/index.mld" blog_index;

  (* Output recent entries for main index *)
  Printf.printf "\n=== Recent entries (copy to index.mld) ===\n\n";
  Printf.printf "{1 Recent entries}\n\n";
  print_endline (generate_recent_entries posts 10);
  print_endline ""
