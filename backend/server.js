
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const crypto = require("crypto");

const app = express();
const PORT = process.env.PORT || 3000;
const API_URL = "https://api.fiveonepay.com/v1";

// Stockage temporaire pour les tests.
// En production, utiliser une base de données.
const processedWebhookEvents = new Set();
const webhookPaymentStatuses = new Map();

// ============================================================
// MIDDLEWARES
// ============================================================

app.use(cors());

// Conserver le corps brut pour vérifier la signature du webhook.
app.use(
  express.json({
    verify: (req, res, buffer) => {
      if (
        req.originalUrl.split("?")[0] ===
        "/api/webhooks/fiveonepay"
      ) {
        req.rawBody = Buffer.from(buffer);
      }
    },
  })
);

// ============================================================
// FONCTIONS UTILITAIRES
// ============================================================

function getSecretKey() {
  return process.env.FIVEONEPAY_SECRET_KEY;
}

function readUrl(value, fieldName, required = false) {
  if (value == null || value === "") {
    if (required) {
      throw new Error(`${fieldName} est obligatoire.`);
    }

    return undefined;
  }

  if (typeof value !== "string") {
    throw new Error(`${fieldName} doit être une URL valide.`);
  }

  let parsed;

  try {
    parsed = new URL(value);
  } catch {
    throw new Error(`${fieldName} doit être une URL valide.`);
  }

  if (!["https:", "http:"].includes(parsed.protocol)) {
    throw new Error(`${fieldName} doit utiliser HTTP ou HTTPS.`);
  }

  return parsed.toString();
}

async function readJson(response) {
  const text = await response.text();

  try {
    return JSON.parse(text);
  } catch {
    return {
      message:
        text ||
        response.statusText ||
        "Réponse API invalide.",
    };
  }
}

async function getOperators() {
  const response = await fetch(
    `${API_URL}/public/operators`
  );

  const data = await readJson(response);

  return { response, data };
}

async function getActiveOperator(operator) {
  const { response, data } = await getOperators();

  if (!response.ok || !Array.isArray(data)) {
    throw new Error("OPERATORS_UNAVAILABLE");
  }

  return (
    data.find(
      (item) =>
        item.operator === operator &&
        item.is_active === true
    ) || null
  );
}

function validateAmountForOperator(amount, operatorData) {
  if (
    amount < operatorData.min_amount ||
    amount > operatorData.max_amount
  ) {
    return (
      `Le montant doit être compris entre ` +
      `${operatorData.min_amount} Ar et ` +
      `${operatorData.max_amount} Ar pour cet opérateur.`
    );
  }

  return null;
}

function getPagination(req) {
  const page = Number(req.query.page ?? 1);
  const limit = Number(req.query.limit ?? 20);

  if (!Number.isInteger(page) || page < 1) {
    return {
      error: "page doit être un entier supérieur ou égal à 1.",
    };
  }

  if (!Number.isInteger(limit) || limit < 1 || limit > 100) {
    return {
      error: "limit doit être compris entre 1 et 100.",
    };
  }

  return { page, limit };
}

function validateOptionalNonNegativeInteger(value, fieldName) {
  if (
    value !== undefined &&
    (!Number.isInteger(value) || value < 0)
  ) {
    return (
      `${fieldName} doit être un entier supérieur ou égal à 0.`
    );
  }

  return null;
}

// ============================================================
// VÉRIFIER LE SERVEUR
// GET /
// ============================================================

app.get("/", (req, res) => {
  res.send("FiveOne Pay Backend fonctionne !");
});



// ============================================================
// CONSULTER LE SOLDE FIVEONE PAY
// GET /api/balance
// ============================================================

app.get("/api/balance", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    const response = await fetch(`${API_URL}/balance`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${secretKey}`,
        Accept: "application/json",
      },
    });

    const data = await readJson(response);

    if (!response.ok) {
      console.error("Erreur consultation solde :", data);

      return res.status(response.status).json(data);
    }

    return res.json({
      balance: data.balance,
      currency: data.currency,
      environment: data.environment,
    });
  } catch (error) {
    console.error(
      "Erreur consultation solde :",
      error.message
    );

    return res.status(502).json({
      message:
        "Impossible de récupérer le solde FiveOne Pay.",
    });
  }
});

// ============================================================
// RÉCUPÉRER LES OPÉRATEURS
// GET /api/operators
// ============================================================

app.get("/api/operators", async (req, res) => {
  try {
    const { response, data } = await getOperators();

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error("Erreur opérateurs :", error.message);

    return res.status(502).json({
      message:
        "Impossible de récupérer les opérateurs FiveOne Pay.",
    });
  }
});

// ============================================================
// CRÉER UN PAIEMENT CLASSIQUE
// POST /api/payments
//
// Champs :
// amount, reference, operator, description, payerNumber,
// expiresInMinutes, successUrl, cancelUrl.
// callbackUrl est configuré dans .env.
// ============================================================

app.post("/api/payments", async (req, res) => {
  try {
    const {
      amount,
      reference,
      operator,
      description,
      payerNumber,
      expiresInMinutes = 15,
      successUrl,
      cancelUrl,
    } = req.body;

    if (!Number.isInteger(amount) || amount <= 0) {
      return res.status(400).json({
        message:
          "Le montant doit être un entier positif en Ariary.",
      });
    }

    if (
      typeof reference !== "string" ||
      !reference.trim()
    ) {
      return res.status(400).json({
        message: "La référence est obligatoire.",
      });
    }

    if (reference.length > 255) {
      return res.status(400).json({
        message:
          "La référence ne doit pas dépasser 255 caractères.",
      });
    }

    if (
      typeof operator !== "string" ||
      !operator.trim()
    ) {
      return res.status(400).json({
        message: "Veuillez sélectionner un opérateur.",
      });
    }

    if (
      description !== undefined &&
      (typeof description !== "string" ||
        description.length > 255)
    ) {
      return res.status(400).json({
        message:
          "La description ne doit pas dépasser 255 caractères.",
      });
    }

    if (
      !Number.isInteger(expiresInMinutes) ||
      expiresInMinutes < 15 ||
      expiresInMinutes > 1440
    ) {
      return res.status(400).json({
        message:
          "La validité doit être comprise entre 15 et 1440 minutes.",
      });
    }

    if (
      payerNumber !== undefined &&
      (typeof payerNumber !== "string" ||
        !payerNumber.trim())
    ) {
      return res.status(400).json({
        message: "Le numéro du client est invalide.",
      });
    }

    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    const validatedSuccessUrl = readUrl(
      successUrl,
      "URL de succès"
    );

    const validatedCancelUrl = readUrl(
      cancelUrl,
      "URL d'annulation"
    );

    const callbackUrl = readUrl(
      process.env.FIVEONE_CALLBACK_URL,
      "FIVEONE_CALLBACK_URL"
    );

    if (
      callbackUrl &&
      !callbackUrl.startsWith("https://")
    ) {
      return res.status(400).json({
        message:
          "FIVEONE_CALLBACK_URL doit être une URL HTTPS.",
      });
    }

    const selectedOperator =
      await getActiveOperator(operator);

    if (!selectedOperator) {
      return res.status(400).json({
        message: "Opérateur indisponible ou invalide.",
      });
    }

    const amountError = validateAmountForOperator(
      amount,
      selectedOperator
    );

    if (amountError) {
      return res.status(400).json({
        message: amountError,
      });
    }

    const paymentData = {
      amount,
      reference: reference.trim(),
      operator,
      expiresInMinutes,
    };

    if (description?.trim()) {
      paymentData.description = description.trim();
    }

    if (payerNumber?.trim()) {
      paymentData.payerNumber = payerNumber.trim();
    }

    if (callbackUrl) {
      paymentData.callbackUrl = callbackUrl;
    }

    if (validatedSuccessUrl) {
      paymentData.successUrl = validatedSuccessUrl;
    }

    if (validatedCancelUrl) {
      paymentData.cancelUrl = validatedCancelUrl;
    }

    const paymentResponse = await fetch(
      `${API_URL}/payments`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          "Idempotency-Key": reference.trim(),
        },
        body: JSON.stringify(paymentData),
      }
    );

    const result = await readJson(paymentResponse);

    if (!paymentResponse.ok) {
      console.error(
        "Erreur création paiement FiveOne Pay :",
        result
      );

      return res.status(paymentResponse.status).json({
        message:
          result.message ||
          "La création du paiement a échoué.",
        details: result,
      });
    }

    return res.status(201).json({
      id: result.id,
      status: result.status,
      environment: result.environment,
      amount: result.amount,
      payable_amount: result.payable_amount,
      currency: result.currency,
      commission: result.commission,
      net_amount: result.net_amount,
      reference: result.reference,
      fiveonepay_reference: result.fiveonepay_reference,
      operator: result.operator,
      payment_url: result.payment_url,
      expires_at: result.expires_at,
      created_at: result.created_at,
    });
  } catch (error) {
    console.error("Erreur paiement :", error.message);

    if (error.message === "OPERATORS_UNAVAILABLE") {
      return res.status(502).json({
        message: "Impossible de vérifier les opérateurs.",
      });
    }

    return res.status(400).json({
      message:
        error.message ||
        "Erreur lors de la création du paiement.",
    });
  }
});

// ============================================================
// CRÉER UN LIEN DE PAIEMENT RÉUTILISABLE
// POST /api/payment-links
// ============================================================

app.post("/api/payment-links", async (req, res) => {
  try {
    const { amount, description, operator } = req.body;

    if (!Number.isInteger(amount) || amount <= 0) {
      return res.status(400).json({
        message:
          "Le montant doit être un entier positif en Ariary.",
      });
    }

    if (
      description !== undefined &&
      (typeof description !== "string" ||
        description.length > 255)
    ) {
      return res.status(400).json({
        message:
          "La description ne doit pas dépasser 255 caractères.",
      });
    }

    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    const linkData = { amount };

    if (description?.trim()) {
      linkData.description = description.trim();
    }

    if (operator !== undefined && operator !== "") {
      if (typeof operator !== "string") {
        return res.status(400).json({
          message: "L'opérateur est invalide.",
        });
      }

      const selectedOperator =
        await getActiveOperator(operator);

      if (!selectedOperator) {
        return res.status(400).json({
          message: "Opérateur indisponible ou invalide.",
        });
      }

      const amountError = validateAmountForOperator(
        amount,
        selectedOperator
      );

      if (amountError) {
        return res.status(400).json({
          message: amountError,
        });
      }

      linkData.operator = operator;
    }

    const response = await fetch(
      `${API_URL}/payment-links`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(linkData),
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      console.error("Erreur création lien :", data);
      return res.status(response.status).json(data);
    }

    return res.status(201).json(data);
  } catch (error) {
    console.error(
      "Erreur lien de paiement :",
      error.message
    );

    if (error.message === "OPERATORS_UNAVAILABLE") {
      return res.status(502).json({
        message:
          "Impossible de récupérer les opérateurs.",
      });
    }

    return res.status(400).json({
      message:
        error.message || "Erreur création lien.",
    });
  }
});

// ============================================================
// HISTORIQUE DES PAIEMENTS
// GET /api/payments?page=1&limit=20&status=SUCCESS
// ============================================================

app.get("/api/payments", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    const pagination = getPagination(req);

    if (pagination.error) {
      return res.status(400).json({
        message: pagination.error,
      });
    }

    const { page, limit } = pagination;

    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    if (req.query.status !== undefined) {
      if (
        typeof req.query.status !== "string" ||
        !req.query.status.trim()
      ) {
        return res.status(400).json({
          message: "Le paramètre status est invalide.",
        });
      }

      params.set("status", req.query.status.trim());
    }

    const response = await fetch(
      `${API_URL}/payments?${params.toString()}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error("Erreur historique :", error.message);

    return res.status(502).json({
      message:
        "Impossible de récupérer l'historique des paiements.",
    });
  }
});

// ============================================================
// RÉCUPÉRER UN PAIEMENT PAR ID
// GET /api/payments/:id
// ============================================================

app.get("/api/payments/:id", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    const paymentId = req.params.id;

    if (!paymentId || !paymentId.trim()) {
      return res.status(400).json({
        message:
          "L'identifiant du paiement est obligatoire.",
      });
    }

    const response = await fetch(
      `${API_URL}/payments/${encodeURIComponent(paymentId)}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error(
      "Erreur consultation paiement :",
      error.message
    );

    return res.status(502).json({
      message: "Impossible de récupérer le paiement.",
    });
  }
});

// ============================================================
// ABONNEMENTS : CRÉER UN PLAN
// POST /api/plans
//
// Champs :
// name, amount, interval, intervalCount, operator,
// maxRetries, retryEveryHrs, graceHrs.
// ============================================================

app.post("/api/plans", async (req, res) => {
  try {
    const {
      name,
      amount,
      interval,
      intervalCount = 1,
      operator,
      maxRetries,
      retryEveryHrs,
      graceHrs,
    } = req.body;

    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    if (
      typeof name !== "string" ||
      !name.trim()
    ) {
      return res.status(400).json({
        message: "Le nom du plan est obligatoire.",
      });
    }

    if (name.length > 255) {
      return res.status(400).json({
        message:
          "Le nom du plan ne doit pas dépasser 255 caractères.",
      });
    }

    if (!Number.isInteger(amount) || amount <= 0) {
      return res.status(400).json({
        message:
          "Le montant doit être un entier positif en Ariary.",
      });
    }

    /*const allowedIntervals = [
      "day",
      "week",
      "month",
      "year",
    ];

    if (!allowedIntervals.includes(interval)) {
      return res.status(400).json({
        message:
          "interval doit être day, week, month ou year.",
      });
    }*/
    const normalizedInterval =
      typeof interval === "string"
        ? interval.toUpperCase()
        : "";

    const allowedIntervals = [
      "DAY",
      "WEEK",
      "MONTH",
      "YEAR",
    ];

    if (!allowedIntervals.includes(normalizedInterval)) {
      return res.status(400).json({
        message:
          "interval doit être DAY, WEEK, MONTH ou YEAR.",
      });
    }

    if (
      !Number.isInteger(intervalCount) ||
      intervalCount < 1 ||
      intervalCount > 365
    ) {
      return res.status(400).json({
        message:
          "intervalCount doit être compris entre 1 et 365.",
      });
    }

    const maxRetriesError =
      validateOptionalNonNegativeInteger(
        maxRetries,
        "maxRetries"
      );

    if (maxRetriesError) {
      return res.status(400).json({
        message: maxRetriesError,
      });
    }

    const retryEveryHrsError =
      validateOptionalNonNegativeInteger(
        retryEveryHrs,
        "retryEveryHrs"
      );

    if (retryEveryHrsError) {
      return res.status(400).json({
        message: retryEveryHrsError,
      });
    }

    const graceHrsError =
      validateOptionalNonNegativeInteger(
        graceHrs,
        "graceHrs"
      );

    if (graceHrsError) {
      return res.status(400).json({
        message: graceHrsError,
      });
    }

    const planData = {
      name: name.trim(),
      amount,
      interval: normalizedInterval,
      intervalCount,
    };

    if (operator !== undefined && operator !== "") {
      if (typeof operator !== "string") {
        return res.status(400).json({
          message: "L'opérateur est invalide.",
        });
      }

      const selectedOperator =
        await getActiveOperator(operator);

      if (!selectedOperator) {
        return res.status(400).json({
          message: "Opérateur indisponible ou invalide.",
        });
      }

      const amountError = validateAmountForOperator(
        amount,
        selectedOperator
      );

      if (amountError) {
        return res.status(400).json({
          message: amountError,
        });
      }

      planData.operator = operator;
    }

    if (maxRetries !== undefined) {
      planData.maxRetries = maxRetries;
    }

    if (retryEveryHrs !== undefined) {
      planData.retryEveryHrs = retryEveryHrs;
    }

    if (graceHrs !== undefined) {
      planData.graceHrs = graceHrs;
    }

    const response = await fetch(
      `${API_URL}/plans`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(planData),
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      console.error(
        "Erreur création plan FiveOne Pay :",
        data
      );

      return res.status(response.status).json(data);
    }

    return res.status(201).json(data);
  } catch (error) {
    console.error(
      "Erreur création plan :",
      error.message
    );

    if (error.message === "OPERATORS_UNAVAILABLE") {
      return res.status(502).json({
        message:
          "Impossible de récupérer les opérateurs.",
      });
    }

    return res.status(400).json({
      message:
        error.message || "Erreur création du plan.",
    });
  }
});

// ============================================================
// ABONNEMENTS : LISTE DES PLANS
// GET /api/plans?page=1&limit=20
// GET /api/plans?page=1&limit=20&active=true
// ============================================================

app.get("/api/plans", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    const pagination = getPagination(req);

    if (pagination.error) {
      return res.status(400).json({
        message: pagination.error,
      });
    }

    const { page, limit } = pagination;

    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    if (req.query.active !== undefined) {
      const activeValue = String(req.query.active)
        .toLowerCase()
        .trim();

      if (
        activeValue !== "true" &&
        activeValue !== "false"
      ) {
        return res.status(400).json({
          message:
            "Le paramètre active doit être true ou false.",
        });
      }

      params.set("active", activeValue);
    }

    const response = await fetch(
      `${API_URL}/plans?${params.toString()}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error(
      "Erreur liste des plans :",
      error.message
    );

    return res.status(502).json({
      message:
        "Impossible de récupérer la liste des plans.",
    });
  }
});

// ============================================================
// ABONNEMENTS : CONSULTER UN PLAN PAR ID
// GET /api/plans/:id
// ============================================================

app.get("/api/plans/:id", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    const planId = req.params.id;

    if (!planId || !planId.trim()) {
      return res.status(400).json({
        message:
          "L'identifiant du plan est obligatoire.",
      });
    }

    const response = await fetch(
      `${API_URL}/plans/${encodeURIComponent(planId)}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error(
      "Erreur consultation plan :",
      error.message
    );

    return res.status(502).json({
      message: "Impossible de récupérer ce plan.",
    });
  }
});

// ============================================================
// ABONNEMENTS : MODIFIER UN PLAN
// PATCH /api/plans/:id
//
// Champs modifiables :
// name, active, maxRetries, retryEveryHrs, graceHrs.
//
// amount et interval ne sont pas modifiables.
// ============================================================

app.patch("/api/plans/:id", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message:
          "La clé API n'est pas configurée côté serveur.",
      });
    }

    const planId = req.params.id;

    if (!planId || !planId.trim()) {
      return res.status(400).json({
        message:
          "L'identifiant du plan est obligatoire.",
      });
    }

    const body = req.body;

    if (
      !body ||
      typeof body !== "object" ||
      Array.isArray(body)
    ) {
      return res.status(400).json({
        message:
          "Le corps de la requête doit être un objet JSON.",
      });
    }

    const allowedFields = [
      "name",
      "active",
      "maxRetries",
      "retryEveryHrs",
      "graceHrs",
    ];

    const receivedFields = Object.keys(body);

    if (receivedFields.length === 0) {
      return res.status(400).json({
        message:
          "Indiquez au moins un champ à modifier.",
      });
    }

    const invalidFields = receivedFields.filter(
      (field) => !allowedFields.includes(field)
    );

    if (invalidFields.length > 0) {
      return res.status(400).json({
        message:
          `Champ(s) non modifiable(s) ou inconnu(s) : ` +
          `${invalidFields.join(", ")}. ` +
          "Champs autorisés : " +
          allowedFields.join(", ") +
          ". Le montant et la périodicité ne sont pas modifiables.",
      });
    }

    const updateData = {};

    if (body.name !== undefined) {
      if (
        typeof body.name !== "string" ||
        !body.name.trim()
      ) {
        return res.status(400).json({
          message:
            "Le nom du plan doit être un texte non vide.",
        });
      }

      if (body.name.length > 255) {
        return res.status(400).json({
          message:
            "Le nom du plan ne doit pas dépasser 255 caractères.",
        });
      }

      updateData.name = body.name.trim();
    }

    if (body.active !== undefined) {
      if (typeof body.active !== "boolean") {
        return res.status(400).json({
          message: "active doit être true ou false.",
        });
      }

      updateData.active = body.active;
    }

    if (body.maxRetries !== undefined) {
      const errorMessage =
        validateOptionalNonNegativeInteger(
          body.maxRetries,
          "maxRetries"
        );

      if (errorMessage) {
        return res.status(400).json({
          message: errorMessage,
        });
      }

      updateData.maxRetries = body.maxRetries;
    }

    if (body.retryEveryHrs !== undefined) {
      const errorMessage =
        validateOptionalNonNegativeInteger(
          body.retryEveryHrs,
          "retryEveryHrs"
        );

      if (errorMessage) {
        return res.status(400).json({
          message: errorMessage,
        });
      }

      updateData.retryEveryHrs = body.retryEveryHrs;
    }

    if (body.graceHrs !== undefined) {
      const errorMessage =
        validateOptionalNonNegativeInteger(
          body.graceHrs,
          "graceHrs"
        );

      if (errorMessage) {
        return res.status(400).json({
          message: errorMessage,
        });
      }

      updateData.graceHrs = body.graceHrs;
    }

    const response = await fetch(
      `${API_URL}/plans/${encodeURIComponent(planId)}`,
      {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(updateData),
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      console.error(
        "Erreur modification plan FiveOne Pay :",
        data
      );

      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error(
      "Erreur modification plan :",
      error.message
    );

    return res.status(502).json({
      message: "Impossible de modifier ce plan.",
    });
  }
});



// ============================================================
// ABONNEMENTS : CRÉER UN CLIENT
// POST /api/customers
// ============================================================

app.post("/api/customers", async (req, res) => {
  try {
    const { phone, name, email, externalRef } = req.body;
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message: "La clé API n'est pas configurée.",
      });
    }

    if (typeof phone !== "string" || !/^0\d{9}$/.test(phone)) {
      return res.status(400).json({
        message: "Le téléphone doit être au format 0XXXXXXXXX.",
      });
    }

    if (name !== undefined && typeof name !== "string") {
      return res.status(400).json({
        message: "Le nom doit être un texte.",
      });
    }

    if (email !== undefined && typeof email !== "string") {
      return res.status(400).json({
        message: "L'e-mail doit être un texte.",
      });
    }

    if (
      externalRef !== undefined &&
      (typeof externalRef !== "string" || !externalRef.trim())
    ) {
      return res.status(400).json({
        message: "externalRef doit être un texte non vide.",
      });
    }

    const customerData = { phone };

    if (name?.trim()) customerData.name = name.trim();
    if (email?.trim()) customerData.email = email.trim();
    if (externalRef?.trim()) {
      customerData.externalRef = externalRef.trim();
    }

    const response = await fetch(`${API_URL}/customers`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${secretKey}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(customerData),
    });

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.status(201).json(data);
  } catch (error) {
    console.error("Erreur création client :", error.message);
    return res.status(502).json({
      message: "Impossible de créer le client.",
    });
  }
});

// ============================================================
// ABONNEMENTS : LISTE DES CLIENTS
// GET /api/customers?page=1&limit=20&externalRef=client-42
// ============================================================

app.get("/api/customers", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message: "La clé API n'est pas configurée.",
      });
    }

    const pagination = getPagination(req);

    if (pagination.error) {
      return res.status(400).json({
        message: pagination.error,
      });
    }

    const params = new URLSearchParams({
      page: String(pagination.page),
      limit: String(pagination.limit),
    });

    if (req.query.externalRef !== undefined) {
      params.set("externalRef", String(req.query.externalRef));
    }

    const response = await fetch(
      `${API_URL}/customers?${params.toString()}`,
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error("Erreur liste clients :", error.message);
    return res.status(502).json({
      message: "Impossible de récupérer les clients.",
    });
  }
});

// ============================================================
// ABONNEMENTS : DÉTAIL D'UN CLIENT
// GET /api/customers/:id
// ============================================================

app.get("/api/customers/:id", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message: "La clé API n'est pas configurée.",
      });
    }

    const response = await fetch(
      `${API_URL}/customers/${encodeURIComponent(req.params.id)}`,
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error("Erreur détail client :", error.message);
    return res.status(502).json({
      message: "Impossible de récupérer ce client.",
    });
  }
});

// ============================================================
// ABONNEMENTS : CRÉER UN ABONNEMENT
// POST /api/subscriptions
//
// Il faut fournir customerId OU un objet customer.
// planId est obligatoire.
// ============================================================

app.post("/api/subscriptions", async (req, res) => {
  try {
    const {
      customerId,
      customer,
      planId,
      callbackUrl,
      startAt,
      billNow,
    } = req.body;

    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message: "La clé API n'est pas configurée.",
      });
    }

    if (typeof planId !== "string" || !planId.trim()) {
      return res.status(400).json({
        message: "planId est obligatoire.",
      });
    }

    if (
      (!customerId && !customer) ||
      (customerId && customer)
    ) {
      return res.status(400).json({
        message:
          "Fournissez customerId ou customer, mais pas les deux.",
      });
    }

    if (
      customerId !== undefined &&
      (typeof customerId !== "string" || !customerId.trim())
    ) {
      return res.status(400).json({
        message: "customerId est invalide.",
      });
    }

    if (customer !== undefined) {
      if (
        !customer ||
        typeof customer !== "object" ||
        Array.isArray(customer) ||
        typeof customer.phone !== "string" ||
        !/^0\d{9}$/.test(customer.phone)
      ) {
        return res.status(400).json({
          message:
            "L'objet customer doit contenir un téléphone au format 0XXXXXXXXX.",
        });
      }

      for (const field of ["name", "email", "externalRef"]) {
        if (
          customer[field] !== undefined &&
          typeof customer[field] !== "string"
        ) {
          return res.status(400).json({
            message: `${field} doit être un texte.`,
          });
        }
      }
    }

    if (billNow !== undefined && typeof billNow !== "boolean") {
      return res.status(400).json({
        message: "billNow doit être true ou false.",
      });
    }

    const subscriptionData = {
      planId: planId.trim(),
    };

    if (customerId) {
      subscriptionData.customerId = customerId.trim();
    }

    if (customer) {
      subscriptionData.customer = customer;
    }

    if (callbackUrl) {
      const validatedCallback = readUrl(
        callbackUrl,
        "callbackUrl"
      );

      if (!validatedCallback.startsWith("https://")) {
        return res.status(400).json({
          message: "callbackUrl doit utiliser HTTPS.",
        });
      }

      subscriptionData.callbackUrl = validatedCallback;
    }

    if (startAt !== undefined) {
      if (
        typeof startAt !== "string" ||
        Number.isNaN(Date.parse(startAt))
      ) {
        return res.status(400).json({
          message: "startAt doit être une date ISO valide.",
        });
      }

      subscriptionData.startAt = startAt;
    }

    if (billNow !== undefined) {
      subscriptionData.billNow = billNow;
    }

    const response = await fetch(`${API_URL}/subscriptions`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${secretKey}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(subscriptionData),
    });

    const data = await readJson(response);

    if (!response.ok) {
      console.error("Erreur abonnement FiveOne Pay :", data);
      return res.status(response.status).json(data);
    }

    return res.status(201).json(data);
  } catch (error) {
    console.error("Erreur création abonnement :", error.message);
    return res.status(400).json({
      message: error.message || "Impossible de créer l'abonnement.",
    });
  }
});

// ============================================================
// ABONNEMENTS : LISTE
// GET /api/subscriptions?page=1&limit=20
// Filtres : status, planId, customerId
// ============================================================

app.get("/api/subscriptions", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message: "La clé API n'est pas configurée.",
      });
    }

    const pagination = getPagination(req);

    if (pagination.error) {
      return res.status(400).json({
        message: pagination.error,
      });
    }

    const params = new URLSearchParams({
      page: String(pagination.page),
      limit: String(pagination.limit),
    });

    for (const field of ["status", "planId", "customerId"]) {
      if (req.query[field] !== undefined) {
        const value = String(req.query[field]).trim();

        if (!value) {
          return res.status(400).json({
            message: `${field} ne peut pas être vide.`,
          });
        }

        params.set(field, value);
      }
    }

    const response = await fetch(
      `${API_URL}/subscriptions?${params.toString()}`,
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error("Erreur liste abonnements :", error.message);
    return res.status(502).json({
      message: "Impossible de récupérer les abonnements.",
    });
  }
});

// ============================================================
// ABONNEMENTS : DÉTAIL
// GET /api/subscriptions/:id
// ============================================================

app.get("/api/subscriptions/:id", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message: "La clé API n'est pas configurée.",
      });
    }

    const response = await fetch(
      `${API_URL}/subscriptions/${encodeURIComponent(req.params.id)}`,
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.json(data);
  } catch (error) {
    console.error("Erreur détail abonnement :", error.message);
    return res.status(502).json({
      message: "Impossible de récupérer cet abonnement.",
    });
  }
});

// ============================================================
// ABONNEMENTS : ANNULER
// DELETE /api/subscriptions/:id
// ============================================================

app.delete("/api/subscriptions/:id", async (req, res) => {
  try {
    const secretKey = getSecretKey();

    if (!secretKey) {
      return res.status(500).json({
        message: "La clé API n'est pas configurée.",
      });
    }

    const response = await fetch(
      `${API_URL}/subscriptions/${encodeURIComponent(req.params.id)}`,
      {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${secretKey}`,
          Accept: "application/json",
        },
      }
    );

    const data = await readJson(response);

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.status(200).json(
      data && Object.keys(data).length
        ? data
        : { cancelled: true }
    );
  } catch (error) {
    console.error("Erreur annulation abonnement :", error.message);
    return res.status(502).json({
      message: "Impossible d'annuler cet abonnement.",
    });
  }
});

// ============================================================
// WEBHOOK SIGNÉ FIVEONE PAY
// POST /api/webhooks/fiveonepay
// ============================================================

app.post("/api/webhooks/fiveonepay", (req, res) => {
  try {
    const webhookSecret =
      process.env.FIVEONE_WEBHOOK_SECRET;

    if (!webhookSecret) {
      console.error(
        "FIVEONE_WEBHOOK_SECRET manquant."
      );

      return res.status(500).send(
        "Configuration webhook manquante."
      );
    }

    const signature = req.get(
      "X-FiveOne-Signature"
    );

    const rawBody = req.rawBody;

    if (
      !signature ||
      !Buffer.isBuffer(rawBody)
    ) {
      return res.status(400).send(
        "Signature ou corps brut manquant."
      );
    }

    // Calcul HMAC-SHA256 selon la documentation.
    const expectedSignature = crypto
      .createHmac("sha256", webhookSecret)
      .update(rawBody)
      .digest("hex");

    if (!/^[a-f0-9]{64}$/i.test(signature)) {
      return res.status(400).send(
        "Signature invalide."
      );
    }

    const receivedBuffer = Buffer.from(
      signature,
      "hex"
    );

    const expectedBuffer = Buffer.from(
      expectedSignature,
      "hex"
    );

    if (
      receivedBuffer.length !==
      expectedBuffer.length ||
      !crypto.timingSafeEqual(
        receivedBuffer,
        expectedBuffer
      )
    ) {
      console.warn(
        "Signature webhook incorrecte."
      );

      return res.status(400).send(
        "Signature invalide."
      );
    }

    // Traiter l'événement après validation de la signature.
    const event = req.body;

    if (
      !event ||
      typeof event !== "object" ||
      typeof event.event !== "string"
    ) {
      return res.status(400).send(
        "Événement invalide."
      );
    }

    const eventId =
      req.get("X-FiveOne-Event-Id") ||
      event.id;

    if (
      typeof eventId !== "string" ||
      !eventId.trim()
    ) {
      return res.status(400).send(
        "Identifiant d'événement manquant."
      );
    }

    if (processedWebhookEvents.has(eventId)) {
      return res.status(200).json({
        received: true,
        duplicate: true,
      });
    }

    const eventName = event.event;
    const payment = event.data;

    if (
      eventName === "payment.success" ||
      eventName === "payment.expired"
    ) {
      if (
        !payment ||
        typeof payment.id !== "string" ||
        !payment.id.trim()
      ) {
        return res.status(400).send(
          "Données du paiement invalides."
        );
      }

      const status =
        eventName === "payment.success"
          ? "SUCCESS"
          : "EXPIRED";

      webhookPaymentStatuses.set(payment.id, {
        ...payment,
        status,
        event: eventName,
        eventId,
        created_at: event.created_at ?? null,
        received_at: new Date().toISOString(),
      });

      console.log(
        `Webhook vérifié : ${eventName} | ` +
        `Paiement ${payment.id} | ${status}`
      );
    } else {
      // Les autres événements, notamment ceux liés aux
      // abonnements, sont acquittés et consignés dans le log.
      console.log(
        "Événement FiveOne Pay reçu :",
        eventName
      );
    }

    // Idempotence temporaire en mémoire.
    processedWebhookEvents.add(eventId);

    return res.status(200).json({
      received: true,
    });
  } catch (error) {
    console.error(
      "Erreur webhook :",
      error.message
    );

    return res.status(500).json({
      message:
        "Erreur lors du traitement du webhook.",
    });
  }
});

// ============================================================
// DÉMARRER LE SERVEUR
// ============================================================

app.listen(PORT, () => {
  console.log(
    `Serveur actif sur http://localhost:${PORT}`
  );

  console.log(
    "Routes disponibles : /api/operators, /api/payments, /api/payment-links, /api/plans"
  );

  console.log(
    "Route webhook : /api/webhooks/fiveonepay"
  );
});
