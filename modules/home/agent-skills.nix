{ lib, ... }:

# One set of skills for every coding agent. Sources live in
# dotfiles/agents/skills/<name>/ and are rendered per harness at eval time.
#
# In *.md files:
#   @skill:NAME@, @spawn@, @ask@, @lsp@   replaced with the harness's wording
#   <!-- harness: omp claude -->          lines kept only for the listed
#   ...                                   harnesses, up to
#   <!-- /harness -->
#
# Optional <skill>/meta.nix (not copied to the output), all keys optional:
#   harnesses   = [ "omp" ];                       only these harnesses get it
#   frontmatter.<harness> = { allowed-tools = …; } extra SKILL.md keys
#   description.<harness> = "…";                   replaces the description
#   exclude.<harness>     = [ "scripts" ];         paths (or dir prefixes) to skip
#   vars.<name>.<harness> = "…";                   skill-local @name@ placeholder
#
# A skill that refers to another skill the harness does not get fails the
# build. Output is read-only store files, so editing a skill needs a rebuild.
# To add a harness, add an entry below.
let
  root = ../../dotfiles/agents/skills;

  harnesses = {
    omp = {
      dir = ".omp/agent/skills";
      spawn = "`task`";
      ask = "`ask`";
      lsp = "`xd://lsp`";
      skill = name: "`skill://${name}`";
    };
    claude = {
      dir = ".claude/skills";
      spawn = "the `Agent` tool";
      ask = "`AskUserQuestion`";
      lsp = "the LSP tool";
      skill = name: "the `${name}` skill";
    };
    pi = {
      dir = ".pi/agent/skills";
      spawn = "a subagent";
      ask = "a direct question to the user";
      lsp = "the language server";
      skill = name: "`/skill:${name}`";
    };
    opencode = {
      dir = ".config/opencode/skills";
      spawn = "the `task` tool";
      ask = "the `question` tool";
      lsp = "the `lsp` tool";
      skill = name: "the `${name}` skill";
    };
    # ~/.codex/skills rather than ~/.agents/skills: other harnesses scan the
    # latter too, which would list every skill twice.
    codex = {
      dir = ".codex/skills";
      spawn = "`spawn_agent`";
      ask = "`request_user_input`";
      lsp = "the language server";
      skill = name: "the `$" + name + "` skill";
    };
    antigravity = {
      dir = ".gemini/config/skills";
      spawn = "a subagent";
      ask = "a direct question to the user";
      lsp = "the language server";
      skill = name: "the `${name}` skill";
    };
  };

  skillNames = builtins.attrNames (builtins.readDir root);

  metaOf =
    name:
    let
      file = root + "/${name}/meta.nix";
    in
    {
      harnesses = builtins.attrNames harnesses;
      frontmatter = { };
      description = { };
      exclude = { };
      vars = { };
    }
    // lib.optionalAttrs (builtins.pathExists file) (import file);

  wantedBy = harness: name: builtins.elem harness (metaOf name).harnesses;

  # Drops <!-- harness: a b --> ... <!-- /harness --> blocks not meant for `harness`.
  selectBlocks =
    harness: text:
    let
      step =
        state: line:
        let
          open = builtins.match "[[:space:]]*<!-- harness: ([^>]*[^ >])[[:space:]]*-->[[:space:]]*" line;
          close = builtins.match "[[:space:]]*<!-- /harness -->[[:space:]]*" line;
        in
        if open != null then
          state // { keep = builtins.elem harness (lib.splitString " " (builtins.head open)); }
        else if close != null then
          state // { keep = true; }
        else if state.keep then
          state // { out = state.out ++ [ line ]; }
        else
          state;
    in
    lib.concatStringsSep "\n" (
      (lib.foldl' step {
        keep = true;
        out = [ ];
      } (lib.splitString "\n" text)).out
    );

  # Applies meta.frontmatter / meta.description to a SKILL.md frontmatter.
  # Values are emitted as JSON, which is valid YAML.
  patchFrontmatter =
    harness: meta: text:
    let
      lines = lib.splitString "\n" text;
      closeAt = lib.lists.findFirstIndex (l: l == "---") null (lib.drop 1 lines);
      front = lib.take closeAt (lib.drop 1 lines);
      rest = lib.drop (closeAt + 2) lines;
      isContinuation = l: l == "" || builtins.match "[[:space:]].*" l != null;
      dropKey =
        key: ls:
        (lib.foldl'
          (
            acc: l:
            if lib.hasPrefix "${key}:" l then
              acc // { skipping = true; }
            else if acc.skipping && isContinuation l then
              acc
            else
              {
                skipping = false;
                out = acc.out ++ [ l ];
              }
          )
          {
            skipping = false;
            out = [ ];
          }
          ls
        ).out;
      extra = meta.frontmatter.${harness} or { };
      withoutOverridden = lib.foldl' (ls: key: dropKey key ls) front (
        builtins.attrNames extra ++ lib.optional (meta.description ? ${harness}) "description"
      );
      added =
        lib.optional (meta.description ? ${harness})
          "description: ${builtins.toJSON meta.description.${harness}}"
        ++ lib.mapAttrsToList (k: v: "${k}: ${builtins.toJSON v}") extra;
    in
    if !(lib.hasPrefix "---" text) || closeAt == null || (added == [ ]) then
      text
    else
      lib.concatStringsSep "\n" ([ "---" ] ++ withoutOverridden ++ added ++ [ "---" ] ++ rest);

  vars =
    h: meta:
    let
      spec = harnesses.${h};
    in
    {
      "@spawn@" = spec.spawn;
      "@ask@" = spec.ask;
      "@lsp@" = spec.lsp;
    }
    // lib.mapAttrs' (
      name: byHarness:
      lib.nameValuePair "@${name}@" (
        byHarness.${h} or (throw "agent-skills: var '${name}' has no value for harness '${h}'")
      )
    ) meta.vars
    // lib.genAttrs' skillNames (name: lib.nameValuePair "@skill:${name}@" (spec.skill name));

  checkRefs =
    h: skill: text:
    let
      refs = lib.concatLists (lib.filter builtins.isList (builtins.split "@skill:([a-z0-9-]+)@" text));
      missing = lib.filter (n: !(builtins.elem n skillNames && wantedBy h n)) refs;
    in
    if missing == [ ] then
      text
    else
      throw "agent-skills: '${skill}' refers to ${lib.concatStringsSep ", " missing}, which harness '${h}' does not get";

  render =
    h: skill: rel: raw:
    let
      meta = metaOf skill;
      selected = checkRefs h skill (selectBlocks h raw);
      body = if rel == "SKILL.md" then patchFrontmatter h meta selected else selected;
      v = vars h meta;
    in
    builtins.replaceStrings (builtins.attrNames v) (builtins.attrValues v) body;

  skillFiles =
    h: name:
    let
      base = root + "/${name}";
      prefix = toString base + "/";
      excluded = (metaOf name).exclude.${h} or [ ];
      skip = rel: rel == "meta.nix" || lib.any (e: rel == e || lib.hasPrefix "${e}/" rel) excluded;
    in
    lib.concatMap (
      path:
      let
        rel = lib.removePrefix prefix (toString path);
      in
      lib.optional (!skip rel) (
        lib.nameValuePair "${harnesses.${h}.dir}/${name}/${rel}" (
          if lib.hasSuffix ".md" rel then
            { text = render h name rel (builtins.readFile path); }
          else
            { source = path; }
        )
      )
    ) (lib.filesystem.listFilesRecursive base);
in
{
  home.file = lib.listToAttrs (
    lib.concatMap (h: lib.concatMap (skillFiles h) (lib.filter (wantedBy h) skillNames)) (
      builtins.attrNames harnesses
    )
  );
}
