{
  description = "Zig 0.17 (master) 开发环境";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Zig 0.17.0-dev (master) - 从官方二进制构建
        zigVersion = "0.17.0-dev.864+3deb86baf";

        zigBinary = pkgs.stdenv.mkDerivation {
          pname = "zig";
          version = zigVersion;

          src =
            if system == "x86_64-linux" then
              pkgs.fetchurl {
                url = "https://ziglang.org/builds/zig-x86_64-linux-${zigVersion}.tar.xz";
                hash = "sha256-UndSpOYV3WeiznMyRq7DC9MwO4uVlTJUCWP5AMJ/lLc=";
              }
            else if system == "aarch64-linux" then
              pkgs.fetchurl {
                url = "https://ziglang.org/builds/zig-aarch64-linux-${zigVersion}.tar.xz";
                hash = "sha256-WLu97MCwAImr3H8AaxwtxmDkv5Ru2pSktmGPb9ZYW3U=";
              }
            else if system == "x86_64-darwin" then
              pkgs.fetchurl {
                url = "https://ziglang.org/builds/zig-x86_64-macos-${zigVersion}.tar.xz";
                hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
              }
            else if system == "aarch64-darwin" then
              pkgs.fetchurl {
                url = "https://ziglang.org/builds/zig-aarch64-macos-${zigVersion}.tar.xz";
                hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
              }
            else
              throw "Unsupported system: ${system}";

          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = with pkgs; [ zlib libxcrypt stdenv.cc.cc.lib ];

          # 跳过不必要的构建阶段
          dontConfigure = true;
          dontBuild = true;

          # 使用 --strip-components=1 去掉 tarball 的顶层目录
          unpackPhase = ''
            runHook preUnpack
            mkdir -p src
            cd src
            tar xf $src --strip-components=1
            runHook postUnpack
          '';

          installPhase = ''
            mkdir -p $out/bin $out/lib $out/share

            cp zig $out/bin/
            cp -r lib/* $out/lib/ 2>/dev/null || true
            cp -r share/* $out/share/ 2>/dev/null || true
          '';

          dontStrip = true;

          meta = with pkgs.lib; {
            description = "Zig programming language (master/0.17.0-dev)";
            homepage = "https://ziglang.org";
            license = licenses.mit;
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            mainProgram = "zig";
          };
        };

      in
      {
        packages = {
          zig = zigBinary;
          default = zigBinary;
        };

        devShells.default = pkgs.mkShell {
          name = "zig-0.17-dev";

          buildInputs = [
            zigBinary
          ];

          shellHook = ''
            echo "Zig $(zig version) 已就绪 (0.17.0-dev master)"
          '';
        };
      });
}
