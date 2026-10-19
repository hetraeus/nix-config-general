mod entry;
mod manager;
mod storage;
mod watcher;
mod wl;

fn main() {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("failed to build tokio runtime");

    if let Err(e) = rt.block_on(manager::run()) {
        eprintln!("fatal: {e:#}");
        std::process::exit(1);
    }
}
