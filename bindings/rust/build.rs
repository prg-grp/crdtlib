fn main() {
  println!("cargo:rerun-if-changed=build.rs");

  let manifest = std::env::var("CARGO_MANIFEST_DIR").unwrap();
  let workspace = format!("{manifest}/../..");

  let lean_out = std::process::Command::new("lean")
    .arg("--print-prefix")
    .output()
    .unwrap()
    .stdout;
  let lean_prefix = std::str::from_utf8(&lean_out).unwrap().trim();

  let lean_dir = format!("{lean_prefix}/lib/lean");
  link_search(&lean_dir);
  println!("cargo:rustc-link-lib=dylib=leanshared");

  let crdtlib_dir = format!("{workspace}/.lake/build/lib");
  link_search(&crdtlib_dir);
  println!("cargo:rustc-link-lib=dylib=crdtlib_Crdtlib");

  pkg_config::probe_library("gmp").unwrap();
  pkg_config::probe_library("libuv").unwrap();

  let packages: &[(&str, &str)] = &[
    ("mathlib", "mathlib_Mathlib"),
    ("Qq", "Qq_Qq"),
    ("aesop", "Aesop_Aesop"),
    ("batteries", "batteries_Batteries"),
    ("importGraph", "importGraph_ImportGraph"),
    ("plausible", "plausible_Plausible"),
    ("proofwidgets", "proofwidgets_ProofWidgets"),
    ("LeanSearchClient", "LeanSearchClient_LeanSearchClient"),
  ];

  for (pkg, stem) in packages {
    let lib_dir = format!("{workspace}/.lake/packages/{pkg}/.lake/build/lib");
    link_search(&lib_dir);
    println!("cargo:rustc-link-lib=dylib={stem}");
  }
}

fn link_search(dir: &str) {
  println!("cargo:rustc-link-search={dir}");
  println!("cargo:rustc-link-arg=-Wl,-rpath,{dir}");
}
