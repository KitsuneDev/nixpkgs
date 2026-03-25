{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  vulkan-headers,
  vulkan-loader,
  python3Packages,

  version ? "0.1.3",
  srcHash ? "sha256-pyIEzVGkMWtFPBFGIpxmuFw8a1lbBAOm2BrpqAwD6Hc="
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "steamvr-linux-fixes";

  inherit version srcHash;

  src = fetchFromGitHub {
    owner = "BnuuySolutions";
    repo = "SteamVRLinuxFixes";
    tag = "v${finalAttrs.version}";
    hash = finalAttrs.srcHash;
    fetchSubmodules = true; # funchook
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
  ];

  env.NIX_CFLAGS_LINK = "-Wl,-z,noexecstack";

  cmakeFlags = [
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DISTORM" "${python3Packages.distorm3.src}")
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 libsteamvr_linux_fixes.so -t $out/lib
    install -dm755 $out/share/vulkan/implicit_layer.d

    cat > $out/share/vulkan/implicit_layer.d/VkLayer_steamvr_linux_fixes.json <<EOF
    {
      "file_format_version": "1.1.0",
      "layer": {
        "name": "VK_LAYER_BNUUY_steamvr_linux_fixes",
        "type": "GLOBAL",
        "library_path": "$out/lib/libsteamvr_linux_fixes.so",
        "api_version": "1.3.200",
        "implementation_version": "1",
        "description": "A Vulkan layer that patches SteamVR's vrcompositor to address issues for wired headsets (Vive, Index, Beyond, PSVR2, etc).",
        "disable_environment": {
          "DISABLE_STEAMVR_LINUX_FIXES": "1"
        }
      }
    }
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Vulkan layer that patches SteamVR vrcompositor for wired HMDs";
    longDescription = ''
      A Vulkan layer that patches SteamVR's vrcompositor to address issues for
      wired headsets (Vive, Index, Beyond, PSVR2, etc), applying fixes such as correct
      refresh rate support, frame presentation latency via VK_KHR_present_wait,
      FIFO_LATEST_READY on NVIDIA, swapchain usage flags for Mesa, and a crash
      on zero-sized texture allocation.

      Add to programs.steam.extraPackages to use with Steam on NixOS. The layer
      activates automatically via the Vulkan implicit layer mechanism and can be
      disabled at runtime by setting DISABLE_STEAMVR_LINUX_FIXES=1.
    '';
    homepage = "https://github.com/BnuuySolutions/SteamVRLinuxFixes";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ Kitsune ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
}
)