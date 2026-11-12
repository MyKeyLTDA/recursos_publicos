# Guía de Integración PlugPay API

**Entornos Sandbox y Producción — PIX, Crédito en Cuotas, QR Paraguay y PIX Out**  
**Versión:** v2.3  
**Fecha:** 14/10/2026  
**Público:** desarrolladores y equipos de integración

## 1. Alcance

Este documento describe las APIs públicas necesarias para operar:

- cobros **PIX**;
- pagos con **Crédito en Cuotas**;
- cobros por **QR Paraguay **.
- transferencias **PIX Out** en Brasil.

No cubre credenciales administrativas, configuraciones bancarias internas ni endpoints internos de conciliación.

### 1.1 Disponibilidad por ambiente

| Entorno | Base URL |
|---|---|
| Sandbox | `https://apisandbox.plugpayapi.com` |
| Producción | `https://api.plugpayapi.com` |

La disponibilidad de monedas, merchants, medios de pago, QR Paraguay y PIX Out depende de la configuración habilitada para cada partner y merchant.

### 1.2 Headers estándar

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <token>
```

Todos los endpoints de negocio requieren `Authorization: Bearer <token>`.

### 1.3 Formato de valores

- Use punto como separador decimal: `10`, `10.50`, `100.00`.
- Para QR Paraguay, el valor debe ser un entero positivo en guaraníes (`PYG`).
- Guarde las referencias devueltas por PlugPay. Son necesarias para consulta, soporte y conciliación.

## 2. Autenticación

### 2.1 Generar token

`POST /v1/partners/auth/token`

```json
{
  "client_id": "SU_CLIENT_ID",
  "password": "SU_CONTRASEÑA"
}
```

Respuesta de ejemplo:

```json
{
  "message": "¡Autenticación realizada con éxito!",
  "token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi..."
}
```

### 2.2 Renovar token

`POST /v1/partners/auth/refresh`

```json
{
  "refresh_token": "REFRESH_TOKEN_RECIBIDO_EN_EL_LOGIN"
}
```

## 3. Prerrequisitos operativos

Antes de crear transacciones, el cliente debe contar con:

| Ítem | Descripción |
|---|---|
| Credenciales de API | `client_id` y `password` del ambiente correspondiente. |
| Merchant registrado | Comercio activo en PlugPay. |
| `documentMerchant` | Documento del merchant, enviado exactamente como fue registrado. |
| URL de retorno | Endpoint HTTPS del cliente para recibir confirmaciones. |
| Token de webhook | Valor configurado para validar las notificaciones. |

## 4. Transacciones PIX

Flujo recomendado: crear el cobro, presentar el QR PIX al cliente, procesar la confirmación por webhook y consultar el estado cuando sea necesario.

### 4.1 Crear cobro PIX

`POST /v1/partners/transactionPix/create`

| Campo | Tipo | Obligatorio | Descripción |
|---|---:|:---:|---|
| `originCurrencie` | string | Sí | Moneda de origen habilitada para el merchant. Ej.: `USD`, `BRL`, `PYG`, `ARS`. |
| `value` | number | Sí | Valor de la transacción en la moneda de origen. |
| `customerCPF` | string | Sí | CPF del cliente brasileño, solo números. |
| `documentMerchant` | string | Sí | Documento del merchant registrado. |

```json
{
  "originCurrencie": "USD",
  "value": 10.00,
  "customerCPF": "CPF_DEL_CLIENTE",
  "documentMerchant": "DOCUMENTO_DEL_MERCHANT"
}
```

Respuesta de ejemplo:

```json
{
  "message": "¡Transacción creada con éxito!",
  "IdTransacao": 889,
  "referenciaInterna": "cb1edd809cb411f1948543742",
  "qrCodeId": "Bcb1edd809cb411f1948543742",
  "qrCodeCopiaCola": "00020101021226880014br.gov.bcb.pix...",
  "valueBRL": "51.00",
  "qrCodeStringImage": "iVBORw0KGgo..."
}
```

### 4.2 Consultar estado PIX

`GET /v1/partners/transactionPix/status/{referenciaInterna}`

```bash
curl -sS \
  "https://apisandbox.plugpayapi.com/v1/partners/transactionPix/status/$REFERENCIA" \
  -H "Authorization: Bearer $TOKEN"
```

### 4.3 Recuperar datos del QR PIX

`GET /v1/partners/transactionPix/qrcode/{referenciaInterna}`

Use esta ruta para recuperar el copia y pega o la imagen del QR de una transacción creada anteriormente.

## 5. Crédito en Cuotas

El flujo de crédito genera una transacción y devuelve una URL de checkout hospedado. Redirija al cliente a esa URL para completar los datos de la tarjeta.

### 5.1 Simular cuotas

`POST /v1/partners/transactionCreditoParcelado/calcularValor`

```json
{
  "originCurrencie": "USD",
  "value": 100.00,
  "qtdParcelas": 3,
  "documentMerchant": "DOCUMENTO_DEL_MERCHANT"
}
```

Respuesta de ejemplo:

```json
{
  "cotacao": "5.10",
  "valorEmUSD": "100.00",
  "valorEmBRL": 510.00,
  "quantidadeParcelas": 3,
  "calculoParcelas": {
    "totalComJuros": 540.60,
    "valorParcela": 180.20
  }
}
```

### 5.2 Iniciar transacción de crédito

`POST /v1/partners/transactionCreditoParcelado/start`

```json
{
  "originCurrencie": "USD",
  "value": 100.00,
  "numberInstallments": 3,
  "customerCPF": "CPF_DEL_CLIENTE",
  "customerPhone": "48999999999",
  "documentMerchant": "DOCUMENTO_DEL_MERCHANT"
}
```

```json
{
  "message": "¡Transacción iniciada con éxito!",
  "IdTransacao": 1240,
  "referenciaInterna": "268584aff056de11f18bcd974cadebcc170523",
  "valueBRL": 540.60,
  "UrlPaymentForm": "https://checkout.cloudpayments2.com.br/..."
}
```

### 5.3 Consultar estado de crédito

`GET /v1/partners/transactionCreditoParcelado/status/{referenciaInterna}`

### 5.4 Cancelar transacción de crédito

`POST /v1/partners/transactionCreditoParcelado/cancel/{referenciaInterna}`

La cancelación está sujeta a elegibilidad de la transacción y a las reglas del proveedor.

## 6. QR Paraguay - 

QR Paraguay permite crear un QR de cobro  en guaraníes. El valor final del QR se define por PlugPay y debe ser enviado en `PYG` como entero positivo.

### 6.1 Crear QR Paraguay

`POST /v1/partners/qr-paraguay/create`

| Campo | Tipo | Obligatorio | Descripción |
|---|---:|:---:|---|
| `documentMerchant` | string | Sí | Documento del merchant habilitado para QR Paraguay/. |
| `originCurrencie` | string | Sí | Debe ser `PYG`. También se acepta `currency` como alias. |
| `value` | integer | Sí | Valor en guaraníes, mayor que cero. |
| `pixOut` | object | No | Instrucción de PIX Out posterior a la confirmación del QR. |

```json
{
  "documentMerchant": "DOCUMENTO_DEL_MERCHANT",
  "originCurrencie": "PYG",
  "value": 1000
}
```

Respuesta de ejemplo:

```json
{
  "ok": true,
  "provider": "",
  "IdTransacao": 19251,
  "serialNumber": "ed73cd690e524cb28b5415bf582b8eee",
  "hookAlias": "SLHNF93812",
  "qrImageUrl": "https://www..com.py/...",
  "qrCodeCopiaCola": "000201...",
  "value": 1000,
  "valueDiscount": 0,
  "valueNet": 1000,
  "currency": "PYG",
  "status": 5
}
```

Guarde `IdTransacao`, `serialNumber` y `hookAlias`.

### 6.2 Consultar estado QR Paraguay

`GET /v1/partners/qr-paraguay/status/{serialNumber}`

```bash
curl -sS \
  "https://apisandbox.plugpayapi.com/v1/partners/qr-paraguay/status/$SERIAL" \
  -H "Authorization: Bearer $TOKEN"
```

Respuesta de ejemplo:

```json
{
  "ok": true,
  "provider": "",
  "serialNumber": "ed73cd690e524cb28b5415bf582b8eee",
  "transaction": {
    "id": 19251,
    "status": 1,
    "valueGross": 1000,
    "valueDiscount": 0,
    "valueNet": 1000,
    "currency": "PYG",
    "hasHookAlias": true
  },
  "providerTransaction": {
    "provider": "",
    "hookAlias": "SLHNF93812",
    "providerStatus": "confirmed",
    "responseCode": "00",
    "authorizationCode": "48300",
    "providerAmount": 1000
  }
}
```



## 8. Webhook de retorno

El webhook es el mecanismo principal de confirmación automática para PIX, crédito y QR Paraguay.

### 8.1 Requisitos del endpoint del cliente

| Ítem | Requisito |
|---|---|
| Protocolo | HTTPS |
| Método | `POST` |
| Formato | JSON |
| Respuesta | `HTTP 200` tras validar la recepción |
| Seguridad | Validar el token/header configurado para el partner |

Ejemplo simplificado de notificación:

```json
{
  "IdTransacao": 889,
  "referenciaInterna": "cb1edd809cb411f1948543742",
  "paymentMethod": "PIX",
  "status": 1,
  "statusDescription": "APROBADO",
  "documentMerchant": "DOCUMENTO_DEL_MERCHANT",
  "value": 10.00,
  "valueBRL": 51.00,
  "currency": "USD",
  "transactionCode": "CODIGO_DE_LA_TRANSACCION",
  "paidAt": "2026-08-20T13:34:21.244Z"
}
```

El cliente debe tratar el webhook de forma idempotente: una misma referencia puede notificarse más de una vez y nunca debe duplicar pedido, entrega, factura o baja financiera.

## 9. Estados de transacción

| Código | Estado | Significado |
|---:|---|---|
| `5` | PENDIENTE DE PAGO | Transacción creada y pendiente de pago/finalización. |
| `1` | APROBADO | Pago confirmado. |
| `3` | RECHAZADO | QR Paraguay rechazado por el proveedor. |
| `6` | CANCELADO | Transacción cancelada o expirada, según el medio. |
| `9` | REVERSADO | Pago revertido, cuando aplique. |

## 10. Buenas prácticas

1. Guarde `IdTransacao`, `referenciaInterna`, `serialNumber`, `hookAlias`, `idTransacao`, `e2e`, `status`, `value`, `valueBRL` y `currency` según corresponda.
2. Procese webhook y consulta de estado con idempotencia.
3. Ante timeout, consulte el estado antes de crear un segundo cobro.
4. Valide siempre la autenticación del webhook y responda rápidamente con `HTTP 200` cuando la recepción sea válida.
5. Homologue cada medio de pago, merchant y moneda en sandbox antes de activarlo en producción.
6. Para QR Paraguay, mantenga los importes en `PYG`; no trate guaraníes como reales brasileños.
7. Para PIX Out directo, no repita una orden por timeout: consulte primero el estado mediante `idTransacao`.

