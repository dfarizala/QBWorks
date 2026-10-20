# QBWorks - Tributo a AppleWorks 3.0 en QB64

## Descripción General
**QBWorks** es un proyecto desarrollado en **QB64** concebido como un tributo nostálgico e funcional al icónico paquete de productividad integrado **AppleWorks 3.0**, lanzado originalmente para la plataforma Apple II en la década de 1980[cite: 1]. El software busca emular la experiencia todo en uno (procesador de textos, hoja de cálculo y base de datos) característica de aquella época dorada de la informática personal.

## Características Principales
* **Interfaz de Usuario Retro:** Simula el entorno visual clásico basado en menús de texto y ventanas modulares típicas de las aplicaciones de los años 80.
* **Sistema Integrado (Modular):** Al igual que el AppleWorks original, el proyecto agrupa diferentes herramientas de productividad bajo un mismo núcleo de gestión de archivos.
* **Componentes Identificados en el Proyecto:**
  * **QBWORKS.BAS:** Archivo fuente principal que controla la lógica de ejecución y la interfaz central.
  * **Módulos de Funcionalidad (`.BM` / utilidades):**
    * *SPELL:* Módulo destinado a la revisión ortográfica o gestión de textos.
    * *WP (Word Processor):* Subsistema dedicado al procesamiento de textos.
    * *SS (Spreadsheet):* Subsistema de hoja de cálculo para la gestión de datos numéricos.
    * *DB (Database):* Componente de base de datos para organizar registros estructurados.
    * *CLIP:* Gestor de portapapeles o funciones de copiado/pegado entre módulos.
    * *FILES:* Administrador de archivos interno para abrir, guardar y organizar documentos.
    * *GFX:* Motor o utilidades gráficas para el renderizado en pantalla.
    * *PRINT:* Módulo encargado de la gestión de impresión y salida de documentos.
    * *THEME:* Personalización de la apariencia visual o paleta de colores de la interfaz.

## Tecnologías Utilizadas
* **Lenguaje:** QB64 (un compilador moderno compatible con BASIC que permite crear aplicaciones nativas para sistemas operativos modernos).
* **Fuentes y Recursos:** Incluye tipografías personalizadas (como `PrintChar21.ttf`) para replicar fielmente la estética tipográfica clásica de los ordenadores de 8 de 16 bits.

## Propósito
Este proyecto sirve tanto como un ejercicio de programación avanzada en BASIC como un valioso homenaje histórico, permitiendo a los usuarios modernos experimentar la filosofía de diseño de software eficiente y minimalista de los años 80 en computadoras actuales.