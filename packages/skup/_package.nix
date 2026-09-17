{ lib
, pkgs
, board_list_rasi
, python3
}:

python3.pkgs.buildPythonApplication {
  pname = "skup";
  version = "0.1.0";
  format = "pyproject";

  src = ./.;

  nativeBuildInputs = [
    python3.pkgs.hatchling
    pkgs.makeWrapper
  ];

  postFixup = ''
    wrapProgram $out/bin/skup \
      --prefix PATH : ${lib.makeBinPath [
        pkgs.rofi
        pkgs.xdg-utils
        pkgs.wl-clipboard
      ]} \
      --set BOARD_LIST_RASI ${board_list_rasi}
  '';

  propagatedBuildInputs = [
    # runtime deps: none beyond the stdlib
  ];

  # The package has no tests.
  doCheck = false;

  pythonImportsCheck = [
    "skup"
  ];

  meta = with lib; {
    description = "Robust rofi-based search launcher";
    license = licenses.mit;
    mainProgram = "skup";
    platforms = platforms.linux;
  };
}
