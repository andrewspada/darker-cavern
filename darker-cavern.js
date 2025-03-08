window.addEventListener("load", async () =>
    await Scheme.load_main("darker-cavern.wasm", {
        user_imports: {
            document: {
                get: () => document,
                getElementById: (id) => document.getElementById(id),
            },
            event: {
                addEventListener: (target, type, listener) => target.addEventListener(type, listener),
                keyboardCode: (event) => event.code,
            },
            canvas: {
                getContext: (elem, type) => elem.getContext(type),
                fillRect: (ctx, x, y, w, h) => ctx.fillRect(x, y, w, h),
                clearRect: (ctx, x, y, w, h) => ctx.clearRect(x, y, w, h),
            },
        }
    })
);
