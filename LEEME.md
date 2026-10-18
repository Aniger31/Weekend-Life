# Weekend Life — versión 3 · «Aprender a decir NO» (Nutrilda)

Abre `project.godot` con **Godot 4.7.x** y pulsa F5. La primera vez Godot puede tardar unos segundos en importar.

## Controles
| Acción | Cómo |
|---|---|
| Moverte | Clic en el suelo, o WASD / flechas |
| Usar un objeto | Clic en el objeto (camina solo), o **E / Espacio** si estás cerca |
| Beber café | **C**, o clic en el indicador de café |
| Lista de pendientes | **Tab** (mostrar/ocultar) |
| Pausa | **Esc** |
| Pruebas (ver `Config.ATAJOS_DE_PRUEBA`) | **F9** fuerza una visita · **F10** adelanta 60 min |

Objetos: cama · fregadero · cafetera (preparar/beber) · mesita · planta · puf (leer/ver serie) · escoba y trapeador (trapear/barrer).

## Dónde cambiar cosas
| Quiero cambiar… | Archivo |
|---|---|
| Duración de actividades, costos de energía, energía por café, tazas por preparación, intervalo de visitas (3–6 min), tiempos de advertencia/derrota, ritmo del reloj en tiempo libre | `scripts/config.gd` |
| Diálogos, horas y energía de las 9 interacciones, frases de rechazo, peticiones de café | `scripts/datos_dialogos.gd` |
| Lista de pendientes inicial | `Config.TAREAS` / `Config.ORDEN_TAREAS` |
| Posición de objetos/zonas, obstáculos | `casa_nutri.gd` (constantes `ZONAS`, `OBSTACULOS`) |

## Estructura (lógica separada)
`sistema_reloj.gd` · `sistema_energia.gd` · `sistema_cafe.gd` · `sistema_tareas.gd` · `sistema_visitas.gd` (cada uno independiente, sin interfaz) → `partida.gd` (autoload, los agrupa) → `casa_nutri.gd` (orquesta) → `hud.gd`, `dialogo_ui.gd`, `pantalla_negra.gd`, `menu_acciones.gd`, `vineta_accion.gd`, `pantallas.gd` (interfaz). `musica.gd` (autoload) mantiene música y efectos entre escenas.

## Reglas implementadas
- Día 7:00–22:00, sábado y domingo. 22:00 sábado → «Nutrilda se fue a dormir». 22:00 domingo → pantalla final → créditos → menú.
- Solo el **café** recupera energía. Dormir avanza el tiempo y no restaura energía. Barra roja con ≤ 1/3.
- Pendientes: al completarse salen de la lista. Lo que no hagas el sábado pasa al domingo (etiqueta «ayer»); las tareas diarias reaparecen.
- El contador se pone **en rojo cuando el tiempo que necesitan los pendientes supera el tiempo que queda del fin de semana**. En rojo > 2 min reales → WARNING; si sigue 60 s más → fin de juego (con reinicio).
- «Organizar el descanso nocturno» solo cuenta si duermes a partir de las 19:00 (antes es una siesta).

## Recursos
- **Originales:** fondos, personajes, ilustraciones de acciones, arte de la interfaz (barra, relojes, checklist, íconos), música.
- **Derivados de tus imágenes:** hojas de animación de los 4 personajes (se generaron del PNG de cada uno), fotogramas intermedios (platos sucios→limpios, cama, vapor/destellos/gotas), interfaz recortada sin textos fijos.
- **Provisionales** (mismo estilo, `assets/props/`): puf, set de limpieza, libro, laptop, escoba de mano, rayo, estrella, gota, Zzz.
- **Efectos de sonido** sintetizados (`assets/sfx/`). Tipografía **Fredoka One** (SIL OFL, `assets/fonts/OFL.txt`).
- Los `.wav` originales eran «WAVE extensible 32-bit float», **formato que Godot no importa**. Se convirtieron a PCM 16-bit con el mismo nombre; los originales están en `audio de fondo/originales_float32/` (ignorados por Godot).
- `window/stretch/aspect` pasó de `expand` a `keep` para que la interfaz no se desacomode en otras proporciones de ventana.
- Créditos: sigue habiendo `(TU NOMBRE)` y `(NOMBRE DE QUIEN HIZO LAS ILUSTRACIONES)` para que los completes en `creditos.gd`.
