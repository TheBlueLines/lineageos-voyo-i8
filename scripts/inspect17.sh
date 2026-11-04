#!/bin/bash
V=~/los/vendor/voyo/x970_t10_97inc/proprietary/vendor
find $V -type f \( -name '*.so' -o -path '*/bin/*' \) | while read f; do
  readelf --dyn-syms -W "$f" 2>/dev/null | awk '$7=="UND"{print $8}' | grep -E '^android_(create_namespace|link_namespaces|get_exported_namespace|init_anonymous_namespace|get_LD_LIBRARY_PATH|update_LD_LIBRARY_PATH|dlwarning|link_namespaces_all_libs|init_namespaces)' | sed "s#^#$(basename $f): #"
done | sort | uniq
