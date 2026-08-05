use gpui::{App, Application, Context, IntoElement, Render, Window, WindowOptions, div, px, rgb};

fn main() {
    Application::new().run(|cx: &mut App| {
        if let Err(error) = cx.open_window(WindowOptions::default(), |_, cx| cx.new(|_| Bonsai)) {
            eprintln!("Bonsai could not open its first window: {error}");
        }
    });
}

struct Bonsai;

impl Render for Bonsai {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .size_full()
            .bg(rgb(0x171717))
            .text_color(rgb(0xf5f5f5))
            .flex()
            .flex_col()
            .items_center()
            .justify_center()
            .gap(px(8.0))
            .child(div().text_size(px(28.0)).child("Bonsai"))
            .child(
                div()
                    .text_size(px(14.0))
                    .text_color(rgb(0xa3a3a3))
                    .child("No repository open"),
            )
    }
}
