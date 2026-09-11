echo "  $ alias run='$1 -impl - | ocamlformat - --impl'";
echo "";
cat ./e2e/shared/cases.ml | grep '^type' | while read line; do
  echo '  $ cat <<"EOF" | run';
  echo "  > $line";
  echo '  > EOF';
  echo '';
done
