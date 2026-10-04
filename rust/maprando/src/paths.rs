use std::path::{Path, PathBuf};
use std::sync::OnceLock;

static DATA_ROOT: OnceLock<PathBuf> = OnceLock::new();

/// Set the directory against which relative data paths (e.g. "../patches/ips/foo.ips") are
/// resolved. By default they are resolved against the current working directory, which is
/// expected to be the `rust` directory of the repository.
pub fn set_data_root(root: &Path) -> bool {
    DATA_ROOT.set(root.to_owned()).is_ok()
}

pub fn resolve_data_path(path: &Path) -> PathBuf {
    match DATA_ROOT.get() {
        Some(root) if path.is_relative() => root.join(path),
        _ => path.to_owned(),
    }
}
