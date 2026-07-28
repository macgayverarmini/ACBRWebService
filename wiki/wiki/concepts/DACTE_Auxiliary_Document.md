---
title: DACTE Auxiliary Document Generation Subsystem
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - method/method.acbr.cte.pas
  - routes/route.acbr.cte.pas
tags:
  - dacte
  - cte
  - pdf
  - acbr
  - rendering
---

# DACTE Auxiliary Document Subsystem

The **DACTE (Documento Auxiliar do Conhecimento de Transporte Eletrônico)** subsystem in ACBRWebService renders official PDF transport documents from CT-e XML payloads using the FreePascal / ACBr report generation engine (`TACBrCTeDACTeFPDF`).

---

## Architectural Workflow

```mermaid
sequenceDiagram
    autonumber
    actor Client as HTTP Client (Backend / N8N)
    participant Route as route.acbr.cte.pas
    participant Bridge as TACBRBridgeCTe
    participant Component as TACBrCTe & TACBrCTeDACTeFPDF
    participant Storage as Server Storage (bin/pdf/)

    Client->>Route: POST /cte/dacte or /cte/dacte-url
    Route->>Bridge: Create TACBRBridgeCTe(Config)
    Bridge->>Bridge: ReadXMLFromJSON(xmlData)
    Bridge->>Component: facbr.Conhecimentos.LoadFromString(xml)
    Bridge->>Component: Configure DACTE properties (tiRetrato/tiPaisagem, Preview=False)
    Bridge->>Component: facbr.Conhecimentos.ImprimirPDF()
    Component->>Storage: Save PDF file to bin/pdf/<chave>-cte.pdf
    
    alt POST /cte/dacte
        Bridge->>Storage: Load PDF & convert to Base64
        Bridge-->>Route: Return JSON {chave, url, tamanho, pdf (Base64)}
    else POST /cte/dacte-url
        Bridge-->>Route: Return JSON {chave, url} (No Base64)
    end
    
    Route-->>Client: HTTP 200 OK
    
    opt Direct Download
        Client->>Route: GET /cte/pdf/:chave
        Route->>Storage: Read file bin/pdf/<chave>-cte.pdf
        Route-->>Client: Binary Download (dacte.pdf)
    end
```

---

## Core Components & Configuration

1. **`TACBrCTeDACTeFPDF` Component**:
   - Attached dynamically via `facbr.DACTE := fdacte`.
   - Non-interactive settings enforced for headless execution:
     - `fdacte.MostraPreview := False;`
     - `fdacte.MostraStatus := False;`
     - `fdacte.MostraSetup := False;`

2. **Automatic Layout Orientation**:
   - Evaluates the CT-e layout orientation from `Ide.tpImp`:
     ```pascal
     if facbr.Conhecimentos.Items[0].CTe.Ide.tpImp <> tiPaisagem then
       fdacte.TipoDACTE := tiRetrato
     else
       fdacte.TipoDACTE := tiPaisagem;
     ```

3. **PDF Storage Management**:
   - PDFs are stored in the server's `./pdf/` directory (`ExtractFilePath(ParamStr(0)) + 'pdf'`).
   - Naming convention: `<chave>-cte.pdf` or `CTe<chave>-cte.pdf`.

---

## Route & Performance Profiles

| Route | Payload Return | Best Used For |
| :--- | :--- | :--- |
| `POST /cte/dacte` | Full Base64 PDF + Download URL | Synchronous rendering where client requires immediate embedded PDF bytes. |
| `POST /cte/dacte-url` | Download URL + Key only | Microservices, webhooks, or automation flows (e.g. N8N) to minimize bandwidth. |
| `GET /cte/pdf/:chave` | Direct binary file stream | Direct browser display or downloading PDF attachments. |

---

## Related Pages
- [[CTe_REST_Endpoints]]
- [[ACBRWebService_Architecture]]
- [[JSON_RTTI_Serialization]]
