function jj-search
    for rev in (jj log -r "all()" -T 'change_id.short() ++ "\n"' --no-graph)
        set -l has_match (jj diff -r $rev --git 2>/dev/null | grep -c $argv[1])
        if test "$has_match" -gt 0
            jj log -r $rev --no-graph
            jj diff -r $rev --git 2>/dev/null | awk -v term="$argv[1]" '
                /^diff --git/ { file = $0 }
                {
                    buf[NR] = $0
                    if (NR > 3) delete buf[NR - 4]
                }
                /^[\+\-]/ && index($0, term) {
                    if (file != last_file) {
                        print file
                        last_file = file
                    }
                    count++
                    if (count <= 30) {
                        len = length($0)
                        if (len > 200) {
                            print substr($0, 1, 200) "... [truncated, " len " chars]"
                        } else {
                            for (i = NR - 3; i < NR; i++) {
                                if (i in buf && buf[i] != file) print buf[i]
                            }
                            print $0
                            need_after = 3
                        }
                    }
                    next
                }
                need_after > 0 {
                    len = length($0)
                    if (len > 200) {
                        print substr($0, 1, 200) "... [truncated, " len " chars]"
                        need_after = 0
                    } else {
                        print $0
                        need_after--
                    }
                }
                END {
                    if (count > 30) print "... [" count - 30 " more matches omitted]"
                }
            ' | riff
            echo ""
        end
    end
end
