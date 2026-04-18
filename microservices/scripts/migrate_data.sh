#!/bin/bash
# SmartJudi Data Migration Script
# Exports data from monolith DB and imports into service-specific DBs.
#
# Usage: ./migrate_data.sh <service_name>
#   service_name: legal | auth | notifications | documents | hearings | search | cases
#
# Prerequisites:
#   - Monolith PostgreSQL running and accessible
#   - Target service DB running (via docker-compose)
#   - pg_dump and psql available

set -euo pipefail

SERVICE=${1:-}
MONOLITH_DB_URL="${MONOLITH_DB_URL:-postgres://jood:123456@localhost:5432/smartjudi}"
DUMP_DIR="./data_dumps"

mkdir -p "$DUMP_DIR"

case "$SERVICE" in
  legal)
    echo "=== Migrating Legal Service data ==="
    TABLES=(
      "courts_governorate"
      "courts_district"
      "courts_courttype"
      "courts_courtspecialization"
      "courts_court"
      "courts_court_specializations"
      "laws_legalcategory"
      "laws_law"
      "laws_lawchapter"
      "laws_lawsection"
      "laws_lawarticle"
      "laws_legalarticleflat"
      "laws_legalprocedurenode"
      "laws_caselegalreference"
      "lawyers_lawyer"
      "lawyers_lawyerfilteroptions"
    )
    TARGET_DB_URL="${LEGAL_DB_URL:-postgres://smartjudi:smartjudi_secret@localhost:5435/smartjudi_legal}"
    ;;

  auth)
    echo "=== Migrating Auth Service data ==="
    TABLES=(
      "auth_user"
      "auth_group"
      "auth_permission"
      "auth_user_groups"
      "auth_user_user_permissions"
      "django_content_type"
      "accounts_userprofile"
      "logs_usersession"
    )
    TARGET_DB_URL="${AUTH_DB_URL:-postgres://smartjudi:smartjudi_secret@localhost:5431/smartjudi_auth}"
    ;;

  notifications)
    echo "=== Migrating Notifications Service data ==="
    TABLES=(
      "notifications_notification"
      "messaging_message"
    )
    TARGET_DB_URL="${NOTIF_DB_URL:-postgres://smartjudi:smartjudi_secret@localhost:5436/smartjudi_notifications}"
    ;;

  documents)
    echo "=== Migrating Documents Service data ==="
    TABLES=(
      "attachments_attachment"
      "lawsuits_casefileitem"
    )
    TARGET_DB_URL="${DOCS_DB_URL:-postgres://smartjudi:smartjudi_secret@localhost:5434/smartjudi_documents}"
    ;;

  hearings)
    echo "=== Migrating Hearings Service data ==="
    TABLES=(
      "hearings_hearing"
    )
    TARGET_DB_URL="${HEARINGS_DB_URL:-postgres://smartjudi:smartjudi_secret@localhost:5433/smartjudi_hearings}"
    ;;

  search)
    echo "=== Migrating Search Service data ==="
    TABLES=(
      "logs_searchlog"
      "logs_aichatlog"
    )
    TARGET_DB_URL="${SEARCH_DB_URL:-postgres://smartjudi:smartjudi_secret@localhost:5437/smartjudi_search}"
    ;;

  cases)
    echo "=== Migrating Cases Service data ==="
    TABLES=(
      "lawsuits_case"
      "lawsuits_caseparty"
      "lawsuits_lawsuit"
      "lawsuits_legaltemplate"
      "lawsuits_financialclaim"
      "parties_plaintiff"
      "parties_defendant"
      "responses_response"
      "appeals_appeal"
      "judgments_judgment"
      "payments_paymentorder"
      "audit_auditlog"
    )
    TARGET_DB_URL="${CASES_DB_URL:-postgres://smartjudi:smartjudi_secret@localhost:5432/smartjudi_cases}"
    ;;

  *)
    echo "Usage: $0 <legal|auth|notifications|documents|hearings|search|cases>"
    exit 1
    ;;
esac

echo "Exporting tables from monolith..."
for TABLE in "${TABLES[@]}"; do
  echo "  Dumping $TABLE..."
  pg_dump "$MONOLITH_DB_URL" \
    --table="$TABLE" \
    --data-only \
    --no-owner \
    --no-privileges \
    --disable-triggers \
    > "$DUMP_DIR/${TABLE}.sql" 2>/dev/null || echo "  WARN: $TABLE not found, skipping."
done

echo "Importing into target DB..."
for TABLE in "${TABLES[@]}"; do
  DUMP_FILE="$DUMP_DIR/${TABLE}.sql"
  if [ -f "$DUMP_FILE" ] && [ -s "$DUMP_FILE" ]; then
    echo "  Loading $TABLE..."
    psql "$TARGET_DB_URL" < "$DUMP_FILE" 2>/dev/null || echo "  WARN: Failed to load $TABLE."
  fi
done

echo "=== Migration complete for $SERVICE ==="
