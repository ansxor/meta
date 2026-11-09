# hid-logitech-dd: kernel module of the Logitech TrueForce driver (G923,
# RS50, G PRO). The upstream flake builds it without nixpkgs'
# kernelModuleMakeFlags, so the
# kernel modules aggregation fails ("extra/hid-logitech-dd.ko.cer: No such
# file"). Same build, with those flags.
{
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  src,
  version,
}:

stdenv.mkDerivation {
  pname = "hid-logitech-dd";
  inherit version src;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags;

  buildPhase = ''
    runHook preBuild
    # Call kbuild directly: the module's Makefile wrapper does not forward
    # the cmd_sign override in makeFlags.
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD/mainline $makeFlags modules
    runHook postBuild
  '';

  # modules_install is what runs the kmodigest signing step that writes the
  # .ko.cer certificate the kernel modules aggregation needs.
  installPhase = ''
    runHook preInstall
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD/mainline $makeFlags \
      INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=extra modules_install
    runHook postInstall
  '';

  meta.description = "Kernel module for Logitech TrueForce wheels (G923, RS50, G PRO)";
}
