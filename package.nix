{ lib, stdenv, fetchurl, autoPatchelfHook, wrapGAppsHook3, makeDesktopItem, copyDesktopItems
, alsa-lib, gtk3, dbus-glib, nss, nspr, libpulseaudio, libva, libGL, pciutils
, libX11, libXt, libXtst, libXcomposite, libXdamage, libXrandr, libXcursor, libXi
, adwaita-icon-theme
}:

stdenv.mkDerivation rec {
  pname = "waterfox";
  version = "6.7.6";

  src = fetchurl {
    url = "https://cdn.waterfox.com/waterfox/releases/${version}/Linux_x86_64/waterfox-${version}.tar.bz2";
    hash = lib.fakeHash;
  };

  nativeBuildInputs = [ autoPatchelfHook wrapGAppsHook3 copyDesktopItems ];

  buildInputs = [
    alsa-lib gtk3 dbus-glib nss nspr adwaita-icon-theme
    libX11 libXt libXtst libXcomposite libXdamage libXrandr libXcursor libXi
  ];

  runtimeDependencies = [ libpulseaudio libva libGL pciutils ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib/waterfox
    cp -r . $out/lib/waterfox
    ln -s $out/lib/waterfox/waterfox $out/bin/waterfox
    runHook postInstall
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
