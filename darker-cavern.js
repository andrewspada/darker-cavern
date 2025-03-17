window.addEventListener("load", async () =>
    await Scheme.load_main("darker-cavern.wasm", {
        user_imports: {
            audio: {
                makeAudioContext: () => new AudioContext(),
                decodeAudioData: (audioContext, arrayBuffer) => audioContext.decodeAudioData(arrayBuffer),
                makeAudioBufferSourceNode: (audioContext, audioBuffer) => new AudioBufferSourceNode(audioContext, {buffer: audioBuffer}),
                startAudioBuffer: (audioBufferSourceNode) => audioBufferSourceNode.start(),
                destination: (baseAudioContext) => baseAudioContext.destination,
                connect: (audioNode, destination) => audioNode.connect(destination),
            },
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
                setFillStyle: (ctx, color) => ctx.fillStyle = color,
                setTransform: (ctx, a, b, c, d, e, f) => ctx.setTransform(a, b, c, d, e, f),
                drawImage: (ctx, image, dx, dy) => ctx.drawImage(image, dx, dy),
                fillText: (ctx, text, x, y) => ctx.fillText(text, x, y),
            },
            console: {
                log: (msg) => console.log(msg)
            },
            webSocket: {
                close(ws) { ws.close(); },
                new(url) {
                    ws = new WebSocket(url);
                    ws.binaryType = "arraybuffer";
                    return ws;
                },
                send(ws, data) { ws.send(data); },
                setOnOpen(ws, f) { ws.onopen = (e) => { f(); }; },
                setOnMessage(ws, f) { ws.onmessage = (e) => { f(e.data); }; },
                setOnClose(ws, f) { ws.onclose = (e) => { f(e.code, e.reason); }; }
            },
            window: {
                requestAnimationFrame: (callback) => window.requestAnimationFrame(callback),
                setInterval: (callback, delay) => window.setInterval(callback, delay),
                fetch: (resource) => window.fetch(resource),
                createImageBitmap: (image) => window.createImageBitmap(image),
            },
            uint8Array: {
                new: (length) => new Uint8Array(length),
                fromArrayBuffer: (buffer) => new Uint8Array(buffer),
                length: (array) => array.length,
                ref: (array, index) => array[index],
                set: (array, index, value) => array[index] = value
            },
            crypto: {
                digest: (algorithm, data) => globalThis.crypto.subtle.digest(algorithm, data).then((arrBuf) => new Uint8Array(arrBuf)),
                randomValues(length) {
                    const array = new Uint8Array(length);
                    globalThis.globalThis.crypto.subtle.getRandomValues(array);
                    return array;
                },
                generateEd25519KeyPair: () => globalThis.crypto.subtle.generateKey({ name: "Ed25519" }, true, ["sign", "verify"]),
                keyPairPrivateKey: (keyPair) => keyPair.privateKey,
                keyPairPublicKey: (keyPair) => keyPair.publicKey,
                exportKey: (key) => globalThis.crypto.subtle.exportKey("raw", key).then((arrBuf) => new Uint8Array(arrBuf)),
                importPublicKey: (key) => globalThis.crypto.subtle.importKey("raw", key, { name: "Ed25519" }, true, ["verify"]),
                signEd25519: (data, privateKey) => globalThis.crypto.subtle.sign({ name: "Ed25519" }, privateKey, data).then((arrBuf) => new Uint8Array(arrBuf)),
                verifyEd25519: (signature, data, publicKey) => globalThis.crypto.subtle.verify({ name: "Ed25519" }, publicKey, signature, data)
            },
            promise: {
                then: (promise, onFulfilled, onRejected) => promise.then(onFulfilled, onRejected),
            },
            response: {
                blob: (response) => response.blob(),
                ok: (response) => response.ok,
                arrayBuffer: (response) => response.arrayBuffer(),
            },
            imageBitmap: {
                height: (imageBitmap) => imageBitmap.height,
                width: (imageBitmap) => imageBitmap.width,
            }

        }
    })
);
