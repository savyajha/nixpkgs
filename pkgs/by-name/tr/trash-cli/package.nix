{
  lib,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "trash-cli";
  version = "0.24.5.26";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "andreafrancia";
    repo = "trash-cli";
    rev = version;
    hash = "sha256-ltuMnxtG4jTTSZd6ZHWl8wI0oQMMFqW0HAPetZMfGtc=";
  };

  propagatedBuildInputs = with python3Packages; [
    psutil
    six
  ];

  nativeBuildInputs = with python3Packages; [
    installShellFiles
    shtab
  ];

  nativeCheckInputs = with python3Packages; [
    mock
    pytestCheckHook
  ];

  postPatch = ''
    sed -i '/typing/d' setup.cfg
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    # Create a home directory with a test file.
    HOME="$(mktemp -d)"
    touch "$HOME/deleteme"

    # Verify that trash list is initially empty.
    [[ $($out/bin/trash-list) == "" ]]

    # Trash a test file and verify that it shows up in the list.
    $out/bin/trash "$HOME/deleteme"
    [[ $($out/bin/trash-list) == *" $HOME/deleteme" ]]

    # Empty the trash and verify that it is empty.
    $out/bin/trash-empty
    [[ $($out/bin/trash-list) == "" ]]

    runHook postInstallCheck
  '';
  postInstall = ''
    for bin in trash-empty trash-list trash-restore trash-put trash; do
      installShellCompletion --cmd "$bin" \
        --bash <("$out/bin/$bin" --print-completion bash) \
        --zsh  <("$out/bin/$bin" --print-completion zsh)
    done
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    homepage = "https://github.com/andreafrancia/trash-cli";
    description = "Command line interface to the freedesktop.org trashcan";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.unix;
    license = licenses.gpl2Plus;
    mainProgram = "trash";
  };
}
