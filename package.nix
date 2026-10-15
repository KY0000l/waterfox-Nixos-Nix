{ lib, stdenv, fetchurl, autoPatchelfHook, patchelfUnstable, wrapGAppsHook3
, makeDesktopItem, copyDesktopItems
, alsa-lib, gtk3, dbus-glib, nss, nspr, libpulseaudio, libva, libGL, pciutils
, pipewire, ffmpeg
, libX11, libXt, libXtst, libXcomposite, libXdamage, libXrandr, libXcursor, libXi
, adwaita-icon-theme
}:

stdenv.mkDerivation rec {
  pname = "waterfox";
  version = "6.7.6";

  src = fetchurl {
    url = "https://cdn.waterfox.com/waterfox/releases/${version}/Linux_x86_64/waterfox-${version}.tar.bz2";
    hash = "sha256-kxY7aDUaWKTWZFchm5Xvhv5wZqZSTYG7bKvXR956kFY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    patchelfUnstable
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib gtk3 dbus-glib nss nspr adwaita-icon-theme
    libX11 libXt libXtst libXcomposite libXdamage libXrandr libXcursor libXi
  ];

  # Loaded at runtime via dlopen, so autoPatchelf can't see them
  runtimeDependencies = [ libpulseaudio pipewire libva libGL pciutils ffmpeg ];

  # Mozilla's relrhack breaks if patchelf moves ELF sections around
  patchelfFlags = [ "--no-clobber-old-sections" ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/waterfox $out/share/icons/hicolor/128x128/apps
    cp -r . $out/lib/waterfox
    ln -s $out/lib/waterfox/waterfox $out/bin/waterfox

    icon=$out/lib/waterfox/browser/chrome/icons/default/default128.png
    if [ -f "$icon" ]; then
      ln -s "$icon" $out/share/icons/hicolor/128x128/apps/waterfox.png
    fi

    runHook postInstall
  '';

  # Make dlopen()ed libraries (audio, VA-API, GL) findable at runtime
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        libpulseaudio
        pipewire
        alsa-lib
        libva
        libGL
        pciutils
        ffmpeg
      ]}"
    )
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "waterfox";
      desktopName = "Waterfox";
      exec = "waterfox %U";
      icon = "waterfox";
      categories = [ "Network" "WebBrowser" ];
      mimeTypes = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
    })
  ];

  meta = {
    description = "Privacy-focused Firefox-based browser";
    homepage = "https://www.waterfox.net";
    platforms = [ "x86_64-linux" ];
    mainProgram = "waterfox";
  };
}
