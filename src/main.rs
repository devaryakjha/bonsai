use gpui::{
    App, AppContext as _, Context, IntoElement, ParentElement as _, Render, Styled as _, Window,
    WindowOptions, div,
};
use gpui_component::{
    Root, StyledExt as _,
    button::{Button, ButtonVariants as _},
};

fn main() {
    gpui_platform::application()
        .with_assets(gpui_component_assets::Assets)
        .run(|cx: &mut App| {
            gpui_component::init(cx);

            cx.spawn(async move |cx| {
                if let Err(error) = cx.open_window(WindowOptions::default(), |window, cx| {
                    let view = cx.new(|_| Bonsai);
                    cx.new(|cx| Root::new(view, window, cx))
                }) {
                    eprintln!("Bonsai could not open its first window: {error}");
                }
            })
            .detach();
        });
}

struct Bonsai;

impl Render for Bonsai {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .size_full()
            .v_flex()
            .items_center()
            .justify_center()
            .gap_3()
            .child(div().text_2xl().font_bold().child("Bonsai"))
            .child(div().text_sm().child("No repository open"))
            .child(
                Button::new("open-repository")
                    .primary()
                    .label("Open repository"),
            )
    }
}
