---
name: campus-pdf-patterns
description: Production-grade PDF generation patterns for campus and institutional systems using pdf-lib in SvelteKit/Node.js. Includes standardized CTU header, alignment helpers, tables, watermarks, QR codes, and campus templates (COR, Grade Slip, DTR, Certificates). Use when building, modifying, or reviewing PDF generation, certificates, forms, or report features in SvelteKit or TypeScript.
---

# Campus PDF & Document Generation Patterns (`campus-pdf-patterns`)

This skill defines the production-grade standard for generating pixel-perfect campus documents, institutional certificates, and government forms in **SvelteKit Fullstack (TypeScript / Node.js)** using **`pdf-lib`** and **`@pdf-lib/fontkit`**.

---

## 1. Why `pdf-lib` over Headless Browsers (Puppeteer/HTML)?

For official campus documents (CORs, Grade Slips, DTRs, Billing, Certificates), **`pdf-lib`** with helper functions is the gold standard:
- **Ultra-Fast**: Generates complex documents in **5ms to 20ms** (vs. 1–3 seconds with headless Chromium).
- **Lightweight**: Uses **< 15MB RAM** (vs. 150MB+ per Chromium process), making it safe for low-cost VPS or serverless containers when hundreds of students download grades simultaneously.
- **Pixel-Exact Precision**: Margin, font size, and line thicknesses are 100% deterministic across all printers and PDF viewers.
- **Dual-Copy Layouts**: Easily renders two exact side-by-side copies on a single Letter/A4 page (e.g. CSC Form 48 DTR).

---

## 2. Dependencies & Project Setup

In your SvelteKit / Node.js project:

```bash
pnpm add pdf-lib @pdf-lib/fontkit qrcode
pnpm add -D @types/qrcode
```

Place custom TrueType fonts (e.g. `CourierPrime-Regular.ttf`, `CourierPrime-Bold.ttf`, or `Inter-Regular.ttf`) and official seals (e.g. `ctu.png`) in:
```text
src/lib/assets/
├── ctu.png                     # Official CTU Seal Logo
├── bagong-pilipinas.png        # Secondary/ISO Logo (optional)
└── fonts/
    ├── CourierPrime-Regular.ttf
    ├── CourierPrime-Bold.ttf
    ├── Inter-Regular.ttf
    └── Inter-Bold.ttf
```

---

## 3. Core Render Engine & Alignment Helpers

Create `$lib/server/pdf/engine.ts`:

```typescript
import {
    PDFDocument,
    PDFFont,
    PDFImage,
    PDFPage,
    clip,
    endPath,
    popGraphicsState,
    pushGraphicsState,
    rectangle,
    rgb
} from 'pdf-lib';
import QRCode from 'qrcode';

export type RenderContext = {
    page: PDFPage;
    regularFont: PDFFont;
    boldFont: PDFFont;
    watermark?: PDFImage;
    ctuLogo?: PDFImage;
    secondaryLogo?: PDFImage;
};

export const BLACK = rgb(0, 0, 0);
export const GRAY = rgb(0.3, 0.3, 0.3);
export const CONTENT_OPACITY = 0.85;

// Standard Page Sizes (in points: 1 inch = 72 points)
export const PAGE_SIZES = {
    letter: { width: 612, height: 792 },
    a4: { width: 595.28, height: 841.89 }
} as const;

export type TextOptions = {
    size?: number;
    bold?: boolean;
    color?: typeof BLACK;
    opacity?: number;
};

// Left-aligned text
export function renderText(
    ctx: RenderContext,
    value: string,
    x: number,
    y: number,
    opts: TextOptions = {}
) {
    const font = opts.bold ? ctx.boldFont : ctx.regularFont;
    ctx.page.drawText(value, {
        x,
        y,
        size: opts.size ?? 8,
        font,
        color: opts.color ?? BLACK,
        opacity: opts.opacity ?? CONTENT_OPACITY
    });
}

// Center-aligned text (Auto-computes centerX - width/2)
export function renderCenteredText(
    ctx: RenderContext,
    value: string,
    centerX: number,
    y: number,
    opts: TextOptions = {}
) {
    const size = opts.size ?? 8;
    const font = opts.bold ? ctx.boldFont : ctx.regularFont;
    const textWidth = font.widthOfTextAtSize(value, size);
    renderText(ctx, value, centerX - textWidth / 2, y, opts);
}

// Right-aligned text (Auto-computes rightX - width) - Perfect for grades, money, and units
export function renderRightText(
    ctx: RenderContext,
    value: string,
    rightX: number,
    y: number,
    opts: TextOptions = {}
) {
    const size = opts.size ?? 8;
    const font = opts.bold ? ctx.boldFont : ctx.regularFont;
    const textWidth = font.widthOfTextAtSize(value, size);
    renderText(ctx, value, rightX - textWidth, y, opts);
}

// Line drawing helper
export function renderLine(
    ctx: RenderContext,
    start: { x: number; y: number },
    end: { x: number; y: number },
    thickness = 0.5,
    color = BLACK,
    opacity = CONTENT_OPACITY
) {
    ctx.page.drawLine({ start, end, thickness, color, opacity });
}

// Signatory block helper (Signature line + Printed Name + Designation)
export function renderSignatory(
    ctx: RenderContext,
    name: string,
    title: string,
    x: number,
    y: number,
    lineWidth = 160
): number {
    renderLine(ctx, { x, y }, { x: x + lineWidth, y }, 0.6);
    y -= 10;
    renderCenteredText(ctx, name, x + lineWidth / 2, y, { size: 8.5, bold: true });
    y -= 9;
    renderCenteredText(ctx, title, x + lineWidth / 2, y, { size: 7.5, color: GRAY });
    return y - 10;
}

// Watermark helper with opacity and clipping
export function renderWatermark(
    ctx: RenderContext,
    left: number,
    top: number,
    bottom: number,
    width: number,
    opacity = 0.08
) {
    if (!ctx.watermark) return;
    const height = top - bottom;
    const dims = ctx.watermark.scale(
        Math.max(width / ctx.watermark.width, height / ctx.watermark.height) * 0.75
    );
    ctx.page.pushOperators(
        pushGraphicsState(),
        rectangle(left, bottom, width, height),
        clip(),
        endPath()
    );
    ctx.page.drawImage(ctx.watermark, {
        x: left + (width - dims.width) / 2,
        y: bottom + (height - dims.height) / 2,
        width: dims.width,
        height: dims.height,
        opacity
    });
    ctx.page.pushOperators(popGraphicsState());
}

// Dynamic Verification QR Code
export async function renderQrCode(
    ctx: RenderContext,
    document: PDFDocument,
    textOrUrl: string,
    x: number,
    y: number,
    size = 50
) {
    const pngBuffer = await QRCode.toBuffer(textOrUrl, {
        type: 'png',
        margin: 1,
        width: size * 2
    });
    const qrImage = await document.embedPng(pngBuffer);
    ctx.page.drawImage(qrImage, { x, y, width: size, height: size });
}
```

---

## 4. Standardized Official CTU Letterhead Header (`renderCtuHeader`)

Every official Cebu Technological University document begins with a standardized letterhead. Configurable parameters adapt automatically per campus and department:

```typescript
export type CtuHeaderOptions = {
    campusName?: string;       // Default: "MOALBOAL CAMPUS"
    campusAddress?: string;    // Default: "Poblacion East, Moalboal, Cebu, Philippines"
    department: string;        // e.g. "OFFICE OF THE UNIVERSITY REGISTRAR" or "COLLEGE OF COMPUTER STUDIES"
    website?: string;          // e.g. "www.ctu.edu.ph"
    telNumber?: string;        // e.g. "(032) 474-8103"
    email?: string;            // e.g. "registrar.moalboal@ctu.edu.ph"
    documentTitle?: string;    // e.g. "CERTIFICATE OF REGISTRATION"
    leftMargin?: number;       // Default: 36 (0.5 inch)
    rightMargin?: number;      // Default: 576 (page.width - 36)
};

export function renderCtuHeader(
    ctx: RenderContext,
    y: number,
    opts: CtuHeaderOptions
): number {
    const left = opts.leftMargin ?? 36;
    const right = opts.rightMargin ?? (ctx.page.getWidth() - 36);
    const center = (left + right) / 2;
    const campus = opts.campusName ?? 'MOALBOAL CAMPUS';
    const address = opts.campusAddress ?? 'Poblacion East, Moalboal, Cebu, Philippines';
    const website = opts.website ?? 'www.ctu.edu.ph';
    const tel = opts.telNumber ?? '(032) 474-8103';

    // 1. Draw CTU Seal Logo on Left if available
    const logoSize = 52;
    if (ctx.ctuLogo) {
        ctx.page.drawImage(ctx.ctuLogo, {
            x: left + 10,
            y: y - logoSize + 10,
            width: logoSize,
            height: logoSize
        });
    }

    // 2. Draw Secondary / ISO Logo on Right if available
    if (ctx.secondaryLogo) {
        ctx.page.drawImage(ctx.secondaryLogo, {
            x: right - logoSize - 10,
            y: y - logoSize + 10,
            width: logoSize,
            height: logoSize
        });
    }

    // 3. Official Hierarchy Text
    renderCenteredText(ctx, 'Republic of the Philippines', center, y, { size: 7.5 });
    y -= 10;
    renderCenteredText(ctx, 'CEBU TECHNOLOGICAL UNIVERSITY', center, y, { size: 10.5, bold: true });
    y -= 10;
    renderCenteredText(ctx, campus, center, y, { size: 8.5, bold: true });
    y -= 9;
    renderCenteredText(ctx, address, center, y, { size: 7, color: GRAY });
    y -= 8;

    // Contact info line
    const contactLine = `${website} | Tel. No. ${tel}` + (opts.email ? ` | ${opts.email}` : '');
    renderCenteredText(ctx, contactLine, center, y, { size: 6.5, color: GRAY });
    y -= 12;

    // Department / Office Title
    renderCenteredText(ctx, opts.department.toUpperCase(), center, y, { size: 9, bold: true });
    y -= 8;

    // Divider Line
    renderLine(ctx, { x: left, y }, { x: right, y }, 1.0);
    y -= 2;
    renderLine(ctx, { x: left, y }, { x: right, y }, 0.4);
    y -= 14;

    // Document Title (if provided)
    if (opts.documentTitle) {
        renderCenteredText(ctx, opts.documentTitle.toUpperCase(), center, y, { size: 11, bold: true });
        y -= 16;
    }

    return y; // Returns new Y position ready for body content
}
```

---

## 5. Reusable Dynamic Table Renderer (`renderTable`)

Renders multi-column grids (Grades, Enrolled Subjects, Assessment Fees) with explicit column widths, alignments, and borders:

```typescript
export type ColumnDef<T> = {
    header: string;
    width: number;
    align?: 'left' | 'center' | 'right';
    render: (row: T) => string;
};

export type TableConfig<T> = {
    left: number;
    y: number;
    columns: ColumnDef<T>[];
    rows: T[];
    rowHeight?: number;
    headerHeight?: number;
    fontSize?: number;
};

export function renderTable<T>(ctx: RenderContext, config: TableConfig<T>): number {
    const { left, columns, rows } = config;
    const rowHeight = config.rowHeight ?? 14;
    const headerHeight = config.headerHeight ?? 16;
    const fontSize = config.fontSize ?? 7.5;

    // Calculate column X coordinates
    const colPositions = [left];
    for (const col of columns) {
        colPositions.push(colPositions[colPositions.length - 1] + col.width);
    }
    const right = colPositions[colPositions.length - 1];
    let currentY = config.y;

    // 1. Draw Header Borders
    renderLine(ctx, { x: left, y: currentY }, { x: right, y: currentY }, 0.8);
    const headerBottom = currentY - headerHeight;
    renderLine(ctx, { x: left, y: headerBottom }, { x: right, y: headerBottom }, 0.8);

    // 2. Render Header Text & Vertical Divider Lines
    for (let i = 0; i < columns.length; i++) {
        const col = columns[i];
        const colLeft = colPositions[i];
        const colRight = colPositions[i + 1];
        const colCenter = (colLeft + colRight) / 2;

        renderLine(ctx, { x: colLeft, y: currentY }, { x: colLeft, y: headerBottom }, 0.4);

        if (col.align === 'right') {
            renderRightText(ctx, col.header, colRight - 4, headerBottom + 4, { size: fontSize, bold: true });
        } else if (col.align === 'center') {
            renderCenteredText(ctx, col.header, colCenter, headerBottom + 4, { size: fontSize, bold: true });
        } else {
            renderText(ctx, col.header, colLeft + 4, headerBottom + 4, { size: fontSize, bold: true });
        }
    }
    renderLine(ctx, { x: right, y: currentY }, { x: right, y: headerBottom }, 0.4);

    currentY = headerBottom;

    // 3. Render Data Rows
    for (const row of rows) {
        const rowBottom = currentY - rowHeight;

        for (let i = 0; i < columns.length; i++) {
            const col = columns[i];
            const colLeft = colPositions[i];
            const colRight = colPositions[i + 1];
            const colCenter = (colLeft + colRight) / 2;
            const textValue = col.render(row);

            renderLine(ctx, { x: colLeft, y: currentY }, { x: colLeft, y: rowBottom }, 0.3);

            if (col.align === 'right') {
                renderRightText(ctx, textValue, colRight - 4, rowBottom + 3.5, { size: fontSize });
            } else if (col.align === 'center') {
                renderCenteredText(ctx, textValue, colCenter, rowBottom + 3.5, { size: fontSize });
            } else {
                renderText(ctx, textValue, colLeft + 4, rowBottom + 3.5, { size: fontSize });
            }
        }
        renderLine(ctx, { x: right, y: currentY }, { x: right, y: rowBottom }, 0.3);
        renderLine(ctx, { x: left, y: rowBottom }, { x: right, y: rowBottom }, 0.3);

        currentY = rowBottom;
    }

    return currentY; // Returns bottom of table
}
```

---

## 6. SvelteKit `+server.ts` Endpoint Pattern

Stream the generated PDF directly to the browser for inline preview or attachment download:

```typescript
// src/routes/api/cor/[id]/pdf/+server.ts
import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { generateCorPdf } from '$lib/server/pdf/cor';

export const GET: RequestHandler = async ({ params }) => {
    try {
        const studentId = params.id;
        const pdfBytes = await generateCorPdf(studentId);

        return new Response(pdfBytes, {
            status: 200,
            headers: {
                'Content-Type': 'application/pdf',
                'Content-Disposition': `inline; filename="COR-${studentId}.pdf"`,
                'Cache-Control': 'no-cache'
            }
        });
    } catch (err) {
        console.error('PDF Generation Failed:', err);
        throw error(500, 'Failed to generate PDF document');
    }
};
```
