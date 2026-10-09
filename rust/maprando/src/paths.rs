//! Where Map Rando's data files are. Paths in the code are relative to the repository's `rust` directory (e.g.
//! "../patches/ips"); by default they are opened relative to the current directory, since the website and the CLI run
//! from there. A program that embeds Map Rando and runs elsewhere sets that directory once, before using Map Rando.

use std::path::{Path, PathBuf};
use std::sync::OnceLock;

static RUST_DIR: OnceLock<PathBuf> = OnceLock::new();

/// Sets the `rust` directory the data paths are relative to. Only the first call has an effect; returns whether it was
/// this one.
pub fn set_rust_dir(dir: &Path) -> bool {
    RUST_DIR.set(dir.to_owned()).is_ok()
}

/// A data path, relative to the `rust` directory, as a path to open.
pub fn data_path(relative: impl AsRef<Path>) -> PathBuf {
    match RUST_DIR.get() {
        Some(dir) => dir.join(relative),
        None => relative.as_ref().to_owned(),
    }
}
