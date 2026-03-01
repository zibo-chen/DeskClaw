use crate::frb_generated::StreamSink;
use std::sync::OnceLock;
use tokio::sync::broadcast;

// ──────────────────────── DTOs ────────────────────────────

/// Notification emitted after a cron job finishes execution.
/// Streamed to Flutter so the UI can display a toast and optionally
/// inject the result into a chat session.
#[derive(Debug, Clone)]
pub struct CronNotification {
    /// Cron job ID
    pub job_id: String,
    /// Human-readable job name (may be empty)
    pub job_name: String,
    /// "shell" or "agent"
    pub job_type: String,
    /// "isolated" or "main"
    pub session_target: String,
    /// Actual session ID to inject into (when session_target == "main")
    pub target_session_id: String,
    /// "ok" or "error"
    pub status: String,
    /// Execution output / agent response (truncated)
    pub output: String,
    /// The prompt that was sent (agent jobs only)
    pub prompt: String,
    /// Wall-clock duration in milliseconds
    pub duration_ms: i64,
    /// UTC epoch seconds when the job finished
    pub finished_at: i64,
}

// ──────────────────── Broadcast Channel ──────────────────────

/// Internal broadcast sender — cron_api pushes into this after each job run.
fn notification_sender() -> &'static broadcast::Sender<CronNotification> {
    static TX: OnceLock<broadcast::Sender<CronNotification>> = OnceLock::new();
    TX.get_or_init(|| {
        let (tx, _) = broadcast::channel(64);
        tx
    })
}

/// Called by cron_api after a job completes.
pub(crate) fn emit_notification(notification: CronNotification) {
    // If there are no receivers yet the send will return Err — that's fine.
    let _ = notification_sender().send(notification);
}

// ──────────────────── Flutter Stream API ─────────────────────

/// Subscribe to cron job execution notifications.
/// Flutter calls this once on startup; the sink stays open for the app lifetime.
pub async fn subscribe_cron_notifications(sink: StreamSink<CronNotification>) {
    let mut rx = notification_sender().subscribe();
    loop {
        match rx.recv().await {
            Ok(notification) => {
                if sink.add(notification).is_err() {
                    // Sink closed (Flutter side disposed) — stop relaying.
                    break;
                }
            }
            Err(broadcast::error::RecvError::Lagged(n)) => {
                tracing::warn!("Cron notification subscriber lagged by {n} messages");
                // Continue — next recv will catch up.
            }
            Err(broadcast::error::RecvError::Closed) => {
                break;
            }
        }
    }
}
