function deno-doc-npm
    if test (count $argv) -eq 0
        echo "Usage: deno-doc-npm [-i] <package>[@version]"
        echo "  -i  Interactive mode (fuzzy search symbols with fzf)"
        return 1
    end

    set -l interactive false
    set -l pkg

    for arg in $argv
        switch $arg
            case -i --interactive
                set interactive true
            case '*'
                set pkg $arg
        end
    end

    if test -z "$pkg"
        echo "No package specified"
        return 1
    end

    set -l types_url (curl -sI "https://esm.sh/$pkg" | grep -i '^x-typescript-types:' | awk '{print $2}' | tr -d '\r')

    if test -z "$types_url"
        echo "No TypeScript types found for $pkg"
        return 1
    end

    if test "$interactive" = true
        set -l jsonfile (mktemp)
        set -l jqscript (status dirname)/deno-doc-npm-render.jq

        deno doc --json $types_url 2>/dev/null >$jsonfile

        # Flatten all symbols: top-level + namespace members
        set -l selection (jq -r '
            def collect: .nodes[] | select(.kind != "import") |
                (if .kind == "namespace" then
                    (.namespaceDef.elements[] | "\(.kind)\t\(.name)")
                else
                    "\(.kind)\t\(.name)"
                end);
            [collect] | unique | sort_by(split("\t") | .[1]) | .[]
        ' $jsonfile \
            | fzf --prompt="$pkg> " --delimiter='\t' \
                  --with-nth=1.. \
                  --preview="jq -r --arg kind {1} --arg name {2} -f $jqscript $jsonfile" \
                  --preview-window=wrap)

        if test -z "$selection"
            rm -f $jsonfile
            return 0
        end

        set -l kind (echo $selection | cut -f1)
        set -l name (echo $selection | cut -f2)
        jq -r --arg kind "$kind" --arg name "$name" -f $jqscript $jsonfile

        rm -f $jsonfile
    else
        deno doc $types_url
    end
end
