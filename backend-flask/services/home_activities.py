from datetime import datetime, timedelta, timezone
from opentelemetry import trace
from lib.db import db

class HomeActivities:
  def run(cognito_user_id=None):
    sql = db.template('activities','home')
    results = db.query_array_json(sql)
    return results