# Diseño muestral ENEMDU - logística inferencial (capstone)
setwd("C:/Users/usuar/Documents/capstone")
library(survey)
datos <- read.csv("base_logistica_r.csv")

# 1. Comprobaciones de la base y del diseño
dim(datos)
length(unique(datos$upm))
upm_por_estrato <- tapply(datos$upm, datos$estrato, function(x) length(unique(x)))
length(upm_por_estrato)
sum(upm_por_estrato == 1)
summary(upm_por_estrato)
sum(datos$fexp)
mean(datos$fexp)

# 2. Diseño declarado y tasa de empleo adecuado
diseno <- svydesign(ids = ~upm, strata = ~estrato, weights = ~fexp, data = datos, nest = TRUE)
diseno
tasa <- svymean(~y, diseno)
tasa
confint(tasa)

# Error si se ignorara el diseño y efecto de diseño
se_ingenuo <- sqrt(0.415 * 0.585 / nrow(datos))
se_ingenuo
(SE(tasa) / se_ingenuo)^2

# 3. Logística con el diseño declarado
predictoras <- setdiff(names(datos), c("y", "upm", "estrato", "fexp"))
length(predictoras)
formula_log <- reformulate(predictoras, response = "y")
modelo_svy <- svyglm(formula_log, design = diseno, family = quasibinomial())
summary(modelo_svy)

# 4. Prueba conjunta del bloque educativo
educ <- predictoras[grepl("^(anios_esc|instruccion_|tit_nivel_|tit_campo_)", predictoras)]
length(educ)
regTermTest(modelo_svy, reformulate(educ))
regTermTest(modelo_svy, reformulate(educ[grepl("^tit_campo_", educ)]))
regTermTest(modelo_svy, reformulate(educ[grepl("^instruccion_", educ)]))

# 5. La misma logística con tres tratamientos de fexp
m_frec <- glm(formula_log, data = datos, family = binomial(), weights = fexp)
m_ingenuo <- glm(formula_log, data = datos, family = quasibinomial(), weights = fexp / mean(fexp))
c_frec <- summary(m_frec)$coefficients
c_ing <- summary(m_ingenuo)$coefficients
c_svy <- summary(modelo_svy)$coefficients
comparacion <- data.frame(coef_frec = c_frec[, 1], coef_diseno = c_svy[, 1], se_frec = c_frec[, 2], se_ingenuo = c_ing[, 2], se_diseno = c_svy[, 2], p_frec = c_frec[, 4], p_ingenuo = c_ing[, 4], p_diseno = c_svy[, 4])
round(comparacion, 4)
colSums(comparacion[-1, c("p_frec", "p_ingenuo", "p_diseno")] < 0.05)
summary(comparacion$se_diseno / comparacion$se_ingenuo)
write.csv(comparacion, "comparacion_errores_estandar.csv")

# 6. Tabla de odds ratios con IC 95 % (diseño declarado)
ic <- exp(confint(modelo_svy))
or_tabla <- data.frame(OR = exp(coef(modelo_svy)), IC_inf = ic[, 1], IC_sup = ic[, 2], p = summary(modelo_svy)$coefficients[, 4])
or_tabla <- round(or_tabla[-1, ], 3)
or_tabla
write.csv(or_tabla, "tabla_odds_ratios.csv")

# 7. Análisis opcional 1: edad al cuadrado
diseno <- update(diseno, edad2 = p03^2)
formula_edad2 <- update(formula_log, . ~ . + edad2)
modelo_edad2 <- svyglm(formula_edad2, design = diseno, family = quasibinomial())
summary(modelo_edad2)$coefficients[c("p03", "edad2"), ]
regTermTest(modelo_edad2, ~ p03 + edad2)
b <- coef(modelo_edad2)
-b["p03"] / (2 * b["edad2"])

# Comparación: edad lineal vs. edad en curva
ic2 <- exp(confint(modelo_edad2))
or_tabla2 <- data.frame(OR = exp(coef(modelo_edad2)), IC_inf = ic2[, 1], IC_sup = ic2[, 2], p = summary(modelo_edad2)$coefficients[, 4])
or_tabla2 <- round(or_tabla2[-1, ], 3)
filas <- rownames(or_tabla)
comparar <- data.frame(OR_lineal = or_tabla$OR, p_lineal = or_tabla$p, OR_curva = or_tabla2[filas, "OR"], p_curva = or_tabla2[filas, "p"], row.names = filas)
comparar
sum(or_tabla$p < 0.05)
sum(or_tabla2$p < 0.05)
write.csv(or_tabla2, "tabla_odds_ratios_edad2.csv")

# 8. Análisis opcional 2: prueba conjunta de etnia (modelo con edad en curva)
regTermTest(modelo_edad2, ~ etnia_Afrodescendiente + etnia_Montuvio + etnia_Otros)
