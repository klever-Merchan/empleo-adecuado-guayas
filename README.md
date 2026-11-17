# Predicción del empleo adecuado en la provincia de Guayas mediante XGBoost y SHAP con factores de expansión de la ENEMDU 2025

Repositorio del proyecto de titulación (Capstone) de la Maestría en Inteligencia de Negocios y Ciencia de Datos, Universidad de las Américas (UDLA).

- **Autor:** Klever Ronaldo Merchán Gómez
- **Profesor:** Manuel Eugenio Morocho Cayamcela
- **Año:** 2026

## Objetivo

Desarrollar un modelo predictivo interpretable del acceso al empleo adecuado en la Población Económicamente Activa (PEA) de la provincia de Guayas, con XGBoost, factores de expansión tratados como pesos de diseño e interpretabilidad SHAP, sobre los microdatos de la ENEMDU Anual 2025. La herramienta está pensada para focalizar programas de inserción laboral y formalización.

Tres decisiones atraviesan todo el proyecto:

1. **Sin variables de ingreso ni pobreza.** El empleo adecuado se define en parte por el ingreso, así que usarlo como predictor inflaría el acierto del modelo.
2. **El factor de expansión (`fexp`) como peso de diseño, no de frecuencia,** y la declaración del diseño muestral completo (`upm`, `estrato`, `fexp`), como indica el INEC.
3. **Validación por unidades primarias de muestreo (UPM):** la división en entrenamiento y prueba, la validación cruzada y el bootstrap separan conglomerados completos.

## Datos

La base de la ENEMDU no se incluye en el repositorio por su tamaño. Es pública y se descarga del INEC:

1. Entrar a https://www.ecuadorencifras.gob.ec/enemdu-anual/ y descargar la base de **personas** de la ENEMDU Anual 2025 en formato SPSS.
2. Guardar el archivo como `Datos/ANUAL_2025/BDDenemdu_personas_2025_anual.sav`.

| Elemento | Valor |
| --- | --- |
| Registros de la base de personas (nacional) | 334.786 |
| Variables de la base | 139 |
| PEA de Guayas (15 años y más, sin empleo no clasificado) | 19.525 registros |
| Población representada | 1.862.300 personas |
| UPM / estratos en la PEA de Guayas | 943 / 9 |
| Variable objetivo | `y = 1` si `condact == 1` (empleo adecuado) |
| Tasa ponderada de empleo adecuado | 41,5 % (oficial del INEC: 41,3 %) |

## Estructura del repositorio

```
├── 01_preparacion_base.ipynb    Filtro de la PEA de Guayas y construcción de las 15 predictoras
├── 02_eda_ponderado.ipynb       Caracterización ponderada (objetivo específico 1)
├── 03_modelado.ipynb            XGBoost, regresión logística, bootstrap y SHAP
├── 04_diseno_muestral.R         Regresión logística con el diseño muestral completo
├── requirements.txt
├── Datos/                       Base de modelado y diccionario de variables
├── Modelo/                      Modelos entrenados
└── Resultados/
    ├── Figuras/
    └── Tablas/
```

## Orden de ejecución

| Paso | Archivo | Qué hace | Archivos principales que genera |
| --- | --- | --- | --- |
| 1 | `01_preparacion_base.ipynb` | Filtra la PEA de Guayas, define la variable objetivo y construye las predictoras | `base_modelado.pkl`, `base_modelado.csv` |
| 2 | `02_eda_ponderado.ipynb` | Tasas ponderadas por sexo, edad, zona y educación; sobremuestreo de Guayaquil | Figuras de edad y sexo, zona y educación; `T2_sobremuestreo.csv` |
| 3 | `03_modelado.ipynb` | División por UPM, afinamiento, evaluación en prueba, bootstrap, SHAP, sensibilidad sin etnia y logística con edad² | Modelos, métricas, bootstrap, SHAP y `base_logistica_r.csv` |
| 4 | `04_diseno_muestral.R` | Regresión logística con `svyglm` y diseño muestral completo; comparación de tres tratamientos de `fexp` | `comparacion_errores_estandar.csv`, `tabla_odds_ratios_edad2.csv` |

**Cómo ejecutarlo.** Los notebooks y el script leen y guardan sus archivos en la carpeta donde se ejecutan. Para reproducirlo, colocar los cuatro archivos en una misma carpeta, con la base del INEC en `Datos/ANUAL_2025/`, y ejecutarlos en orden. En este repositorio los resultados ya generados se ordenaron en `Datos`, `Modelo` y `Resultados`.

**Afinamiento.** `afinamiento_xgb_parcial.csv` guarda las combinaciones de hiperparámetros ya evaluadas. Si se copia a la carpeta de trabajo, el notebook 03 lo lee y no repite las 40 combinaciones; si no está, las evalúa desde cero.

**Por qué R.** La regresión logística inferencial se estimó en R con el paquete `survey`, que declara el diseño muestral (UPM, estrato y factor de expansión) y calcula errores estándar por linealización de Taylor. Los modelos predictivos y SHAP se trabajaron en Python.

## Variables predictoras

| Bloque | Variables |
| --- | --- |
| Perfil personal | Sexo (`p02`), edad (`p03`), estado civil (`p06`), parentesco con el jefe de hogar, etnia, lugar de nacimiento (`p15aa`), asiste a clases (`p07`) |
| Educación | Nivel de instrucción, años de escolaridad, nivel del título superior, campo del título superior |
| Hogar | Tamaño del hogar, menores de 5 años, mayores de 65 años |
| Territorio | Zona de residencia (Guayaquil, conurbación, resto urbano, resto rural) |

Las 15 predictoras se codifican en 38 columnas indicadoras (k − 1), las mismas para XGBoost y para la regresión logística. La descripción completa está en la Tabla 7 y en el Anexo 1 de la tesis.

## Resultados principales

Conjunto de prueba: 3.711 registros de 189 UPM. Clase de riesgo: no acceder al empleo adecuado (prevalencia ponderada de 58,3 %).

| Métrica | XGBoost | Regresión logística | Logística con edad² |
| --- | --- | --- | --- |
| AUC | 0,767 | 0,751 | 0,764 |
| Precisión | 0,726 | 0,718 | — |
| Sensibilidad | 0,765 | 0,802 | — |
| F1 | 0,745 | 0,758 | — |
| Precisión en el decil de mayor riesgo | 0,923 | 0,940 | — |

- En el 10 % de mayor riesgo, el 92,3 % de las personas está fuera del empleo adecuado, frente al 58,3 % de una selección al azar, sin usar el ingreso.
- La ventaja de XGBoost es segmentada: frente a la logística con edad², es significativa en educación básica (+0,037 de AUC) y entre los titulados (+0,051), y equivalente en el bachillerato y en el total.
- SHAP identifica la educación como el factor dominante, seguida por el sexo y la zona de residencia, y muestra una relación de U invertida con la edad que la logística confirma (pico cerca de los 41 años).
- Con el factor de expansión como peso de frecuencia, 37 de 38 términos de la logística parecen significativos; con el diseño muestral completo, 13.

## Correspondencia con la tesis

| Tesis | Archivo |
| --- | --- |
| Figura 1. Flujo de la muestra | `Resultados/Tablas/F1_flujo_muestra.csv` |
| Figura 2. Matriz de correlación ponderada | `Resultados/Figuras/matriz_correlacion.png` |
| Figura 3. Tasa por grupo de edad y sexo | `Resultados/Figuras/F_tasa_por_edad_sexo.png` |
| Figura 4. Tasa por zona de residencia | `Resultados/Figuras/F2_tasa_por_zona.png` |
| Figura 5. Tasa por nivel de instrucción y del título | `Resultados/Figuras/F3_tasa_por_educacion.png` |
| Figura 6. Curvas ROC | `Resultados/Figuras/ROC_modelos.png` |
| Figura 7. Matriz de confusión de XGBoost | `Resultados/Figuras/matriz_confusion_xgb.png` |
| Figura 8. Proporción fuera del empleo adecuado por decil | `Resultados/Figuras/F6_precision_por_decil.png` |
| Figura 9. Importancia global SHAP | `Resultados/Figuras/shap_importancia_global.png` |
| Figura 10. Contribución SHAP de la edad | `Resultados/Figuras/shap_numericas.png` |
| Figura 11. Explicación SHAP de las personas A y B | `Resultados/Figuras/shap_cascada_A.png`, `shap_cascada_B.png` |
| Tabla 6. Muestra y población por zona | `Resultados/Tablas/T2_sobremuestreo.csv` |
| Tabla 8. Hiperparámetros de XGBoost | `Resultados/Tablas/afinamiento_xgb.csv` |
| Tabla 9. Desempeño en el conjunto de prueba | `Resultados/Tablas/metricas_prueba.csv`, `bootstrap_prueba.csv` |
| Tabla 10. AUC global y por grupo educativo | `Resultados/Tablas/desempeno_por_grupo_edad2.csv`, `resumen_bootstrap_xgb_vs_edad2.csv` |
| Tabla 13. Significancia según el tratamiento de `fexp` | `Resultados/Tablas/comparacion_errores_estandar.csv` |
| Tabla 14. Odds ratios con edad² | `Resultados/Tablas/tabla_odds_ratios_edad2.csv` |

Los nombres de algunas figuras (`F2_…`, `F3_…`, `F6_…`) conservan la numeración de trabajo y no la de la tesis; esta tabla indica la equivalencia.

## Entorno

- Python 3.12 (entorno de Miniconda). Paquetes en `requirements.txt`.
- R 4.2.2 con el paquete `survey` 4.4.2.

Instalación de los paquetes de Python:

```
pip install -r requirements.txt
```

## Fuente de datos

Instituto Nacional de Estadística y Censos [INEC]. Encuesta Nacional de Empleo, Desempleo y Subempleo (ENEMDU) Anual 2025. https://www.ecuadorencifras.gob.ec/enemdu-anual/
