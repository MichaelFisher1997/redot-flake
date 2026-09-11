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
        
        version = "26.2-stable";
        
        platformInfo = {
          x86_64-linux = {
            url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_linux_x64.zip";
            hash = "sha256-9HTYkIBsQa8VUTz1qGACQ+JBiC4Rto27lWYONGW1seQ=";
            executable = "redot.linuxbsd.editor.x86_64";
          };
          aarch64-linux = {
            url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_linux_arm64.zip";
            hash = "sha256-4HAUbWy+8SDGFXO18SBEhBAK7r1WWrdZ0mrZqIbcEWA=";
            executable = "redot.linuxbsd.editor.arm64";
          };
          x86_64-darwin = {
            url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_macos_universal.zip";
            hash = "sha256-Eoy3vKablaOZioTnKwmQowLOWxkZ37Vs/ccJwsh5Ja4=";
            executable = "Redot.app/Contents/MacOS/Redot";
          };
          aarch64-darwin = {
            url = "https://github.com/Redot-Engine/redot-engine/releases/download/redot-${version}/Redot_v${version}_macos_universal.zip";
            hash = "sha256-Eoy3vKablaOZioTnKwmQowLOWxkZ37Vs/ccJwsh5Ja4=";
            executable = "Redot.app/Contents/MacOS/Redot";
          };
        };

        platform = platformInfo.${system} or (throw "Unsupported system: ${system}");

        redot-icon = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/Redot-Engine/redot-engine/redot-${version}/icon.svg";
          hash = "sha256-OyC2hMAaH/Ugi7cScaAjG2tvCZLz7BslISXeTXoFvH8=";
        };
        
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
            makeWrapper
          ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
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
            vulkan-validation-layers
            
            # X11 support
            libx11
            libxcursor
            libxext
            libxfixes
            libxi
            libxinerama
            libxrandr
            libxrender
            
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
            if [[ "${pkgs.stdenv.hostPlatform.system}" == *"darwin"* ]]; then
              cp -r Redot.app $out/share/redot/
              ln -s $out/share/redot/${platform.executable} $out/bin/redot
              
              # macOS specific setup
              chmod +x $out/share/redot/Redot.app/Contents/MacOS/Redot
            else
              cp ${platform.executable} $out/share/redot/redot-unwrapped
              chmod +x $out/share/redot/redot-unwrapped
              
              # Create wrapper with proper library paths
              makeWrapper $out/share/redot/redot-unwrapped $out/bin/redot \
                --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath (with pkgs; [
                  alsa-lib
                  libpulseaudio
                  dbus
                  fontconfig
                  udev
                  libGL
                  mesa
                  vulkan-loader
                  libx11
                  libxcursor
                  libxext
                  libxfixes
                  libxi
                  libxinerama
                  libxrandr
                  libxrender
                  wayland
                  libxkbcommon
                  glib
                  gtk3
                  zlib
                  stdenv.cc.cc.lib
                ])}" \
                --set LIBGL_DRIVERS_PATH "${pkgs.mesa}/lib/dri" \
                --set VK_LAYER_PATH "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d"

              # XDG desktop integration (rofi drun, app menus, icons)
              install -Dm644 ${redot-icon} $out/share/icons/hicolor/scalable/apps/redot.svg
              mkdir -p $out/share/applications
              cat > $out/share/applications/redot.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Redot Engine
GenericName=Game Engine
Comment=Multi-platform 2D and 3D game engine
Exec=redot %f
Icon=redot
Terminal=false
Categories=Development;Game;IDE;
MimeType=application/x-redot-project;
StartupWMClass=Godot_Engine
EOF
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