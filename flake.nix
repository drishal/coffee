{
  description = "Cross compiling a rust program for windows";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, crane, fenix, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        toolchain = with fenix.packages.${system};
          combine [
            minimal.rustc
            minimal.cargo
            targets.x86_64-pc-windows-gnu.latest.rust-std
          ];

        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

        my-crate = craneLib.buildPackage {
          # inherit python-server;
          src = craneLib.cleanCargoSource (craneLib.path ./.);

          strictDeps = true;
          doCheck = false;

          CARGO_BUILD_TARGET = "x86_64-pc-windows-gnu";

          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
          OPENSSL_DIR = "${pkgs.openssl.dev}";
          OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib";
          OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include/";
          TARGET_CC = "${pkgs.pkgsCross.mingwW64.stdenv.cc}/bin/${pkgs.pkgsCross.mingwW64.stdenv.cc.targetPrefix}cc";

          depsBuildBuild = with pkgs; [
            pkgsCross.mingwW64.stdenv.cc
            pkgsCross.mingwW64.windows.pthreads
            pkgsCross.mingwW64.libxcrypt
            rust-analyzer
            taplo
            # openssl
            # openssl.dev
            # pkg-config
            # libiconv
            python3
            python3Packages.pip
            # python3Packages.venvShellHook
            virtualenv
          ];

          # venvDir = "./.venv";
          # Run this command, only after creating the virtual environment
          # postVenvCreation = ''
          #     unset SOURCE_DATE_EPOCH
          #     pip install -r requirements.txt
          # '';

          # Now we can execute any commands within the virtual environment.
          # This is optional and can be left out to run pip manually.
          postShellHook = ''
              # allow pip to install wheels
                  unset SOURCE_DATE_EPOCH
          '';

          # installPhase = "cargo fetch";

          #dummy variables
          AESPSK="{'dec_key': null, 'enc_key': null, 'value': 'none'}";
          callback_host="http://127.0.0.1";
          callback_interval=10; callback_jitter=23; callback_port=80; encrypted_exchange_check=true;
          get_uri="index" ;
          headers="{'User-Agent: Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko}";
          killdate="2025-03-11";
          post_uri="data";
          proxy_host="";
          proxy_pass="";
          proxy_port=""; proxy_user="";
          query_path_name="q"; UUID="f159cf19-a492-4995-9a85-bdca5b123ed7"; daemonize="False";
          connection_retries="1";
          working_hours="00:00-23:59"; 
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc
            # Add any missing library needed
            # You can use the nix-index package to locate them, e.g. nix-locate -w --top-level --at-root /lib/libudev.so.1
          ];
          # shellHook = ''
          # source venv/bin/activate
          # '';
        };
        # python-server = {
        #   shellHook = ''
        #    source .venv/bin/activate
        #   '';
        # };
        # python-server = pkgs.stdenv.mkDerivation {
        #   name = "python-server";
        #   inherit my-crate;
        #   BuildInputs = [
        #     (pkgs.python3.withPackages (python3Packages: with python3Packages; [
        #       pip
        #       pkgs.virtualenv
        #     ]))
        #   ];
        #   dontUnpack = true;
        #   shellHook = ''
        #   virtualenv .venv
        #   source .venv/bin/activate
        #   pip3 install -r requirements.txt
        #   '';
        #   installPhase = "install -Dm755 ${./main.py} $out/bin/main.py";
        #   runPhase = "${pkgs.python3} ${./main.py}";
        # };

      in
        {
          packages = {
            inherit my-crate;
            # inherit python-server;
            default = my-crate;
          };
          checks = {
            inherit my-crate;
          };
        }
    );
}
