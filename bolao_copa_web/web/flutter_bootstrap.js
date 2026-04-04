{{flutter_js}}
{{flutter_build_config}}

// Força CanvasKit para maior compatibilidade (Skwasm/multithread pode falhar sem headers COOP/COEP).
_flutter.loader.load({
  config: {
    renderer: "canvaskit",
  },
});
