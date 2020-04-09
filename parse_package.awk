BEGIN{
  PKG_NAME="";
  };
/include .*\/luci\.mk/ {
  PDIR=FILENAME; gsub(/\/Makefile$/, "", PDIR);
  PKG_NAME=PDIR; gsub(/^.*[^/]*\//, "", PKG_NAME);
  printf("echo %s %s\nPDIR=%s\nPKG_NAME=%s\n", PDIR, PKG_NAME, PDIR, PKG_NAME);
  $0=sprintf("$(eval $(call BuildPackage %s %s %s))\n", PDIR, PKG_NAME, PKG_NAME);
  print; printf("echo \x27\t+%s\x27\n", gensub(/^.*\$call ([^ ]*) ([^ ]*) ([^ ]*) (.*)$/, "\\1 \\3,\\4 \\2", "1")); 
  next;};
/PRG_NAME:=.*$/ {
  printf("echo skiped: %s\n", $0);
  next;};
/PKG_NAME:=.*$/ {
  PDIR=FILENAME; gsub(/\/Makefile$/, "", PDIR);
  PKG_NAME=gensub(/[^=]*=(.*)$/, "\\1", "1");
  printf("echo %s %s\nPDIR=%s\nPKG_NAME=%s\n", PDIR, PKG_NAME, PDIR, PKG_NAME);
  next;};
/^PKG_VERSION:=.*$/ {
  printf("PKG_VERSION=\x27%s\x27\n", gensub(/[^=]*=(.*)$/, "\\1", "1"));
  next;};
/^[^#]*[^ \t](NAME|VERSION):=[^$\\]+$/ {
  print gensub(/^(.*):=(.*)$/, "\\1=\x27\\2\x27", "1");
  print gensub(/^(.*):=.*$/, "\\1() { echo ${\\1:-ERROR_\\1}; }", "1");
  next;};
/^[ \t]*\$\(eval[^$]*\$\(call[^,]*,.*\\$/ { next; };
/^[ \t]*\$\(eval[^$]*\$\(call.*[@ ]\(.*$/ { next; };
/^[ \t]*\$\(eval[^$]*\$\(call[^,]*,[^,]*$/ {
  if(PKG_NAME == "") {next; };
  if(PKG_NAME == "libupm") {print "echo skiped libupm"; next; };
  gsub(/,/, sprintf(" %s %s ", PDIR, PKG_NAME));
  print; gsub(/[ \t]/, ","); gsub(/,,/, ",");
  gsub(/[()]/, ""); printf("echo \x27\t+%s\x27\n", gensub(/^.*\$call,([^,]*),([^,]*),([^,]*),(.*)$/, "\\1 \\3,\\4 \\2", "1")); 
  next;
}

