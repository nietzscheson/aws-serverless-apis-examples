{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    cmake
    poetry
    jq
    nodejs_20
  ];

  buildInputs = with pkgs; [
    terraform
    python39Packages.pip
    python311Packages.debugpy
    terraformer
  ];

  packages = with pkgs; [
    git
    neovim
    python311
    pypy3
    awscli
    httpie
    ruff
    pre-commit
  ];

  GIT_EDITOR = "${pkgs.neovim}/bin/nvim";

  shellHook = ''
    export PATH=$PATH:${pkgs.poetry}/bin
    if [ -z "$VIRTUAL_ENV" ]; then
      echo "Creating a virtual environment for the project..."
      poetry config virtualenvs.in-project true
    fi
    #make terraform.init
    #export $(terraform -chdir=infra output -json | jq -r 'to_entries|map("\(.key | ascii_upcase)=\(.value.value)")|.[]' | xargs)
    #aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  '';
}