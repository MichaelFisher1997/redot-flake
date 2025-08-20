{
  description = "Redot Engine - A community-driven fork of Godot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        version = "4.3.1-stable";
        
        platformInfo = {
          x86_64-linux = {
            url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_linux.x86_64.zip";
            hash = "sha256-utdrU+GFRkj7o/O2MbmWoWDljxtzB24emxhU+NGsbwU=";
            executable = "Redot_v${version}_linux.x86_64";
          };
          aarch64-linux = {
            url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_linux.arm64.zip";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will be updated by automation
            executable = "Redot_v${version}_linux.arm64";
          };
          x86_64-darwin = {
            url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_macos.universal.zip";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will be updated by automation
            executable = "Redot.app/Contents/MacOS/Redot";
          };
          aarch64-darwin = {
            url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_macos.universal.zip";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will be updated by automation
            executable = "Redot.app/Contents/MacOS/Redot";
          };
        };

        platform = platformInfo.${system} or (throw "Unsupported system: ${system}");
        
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "redot";
          inherit version;

          src = pkgs.fetchurl {
            url = platform.url;
            hash = platform.hash;
          };

          nativeBuildInputs = with pkgs; [
            unzip
            autoPatchelfHook
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            wrapGAppsHook4
          ];

          buildInputs = with pkgs; [
            # Audio
            alsa-lib
            libpulseaudio
            
            # Core system
            dbus
            fontconfig
            udev
            
            # Graphics
            libGL
            mesa
            vulkan-loader
            
            # X11 support
            xorg.libX11
            xorg.libXcursor
            xorg.libXext
            xorg.libXfixes
            xorg.libXi
            xorg.libXinerama
            xorg.libXrandr
            xorg.libXrender
            
            # Wayland support
            wayland
            libxkbcommon
            
            # Additional runtime deps
            glib
            gtk3
            zlib
            stdenv.cc.cc.lib
          ];

          dontConfigure = true;
          dontBuild = true;
          
          sourceRoot = ".";

          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/bin $out/share/redot
            
            # Handle different platforms
            if [[ "$system" == *"darwin"* ]]; then
              cp -r Redot.app $out/share/redot/
              ln -s $out/share/redot/${platform.executable} $out/bin/redot
              
              # macOS specific setup
              chmod +x $out/share/redot/Redot.app/Contents/MacOS/Redot
            else
              cp ${platform.executable} $out/bin/redot
              chmod +x $out/bin/redot
            fi
            
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Multi-platform 2D and 3D game engine - Community fork of Godot";
            homepage = "https://github.com/Redot-Engine/redot-engine";
            license = licenses.mit;
            maintainers = [ ];
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            sourceProvenance = with sourceTypes; [ binaryNativeCode ];
          };
        };

        packages.redot = self.packages.${system}.default;

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/redot";
        };

        apps.redot = self.apps.${system}.default;
      });
}