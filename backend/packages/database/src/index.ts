import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/upaying',
});

export const prisma = {
  $connect: async () => pool.connect(),
  $disconnect: async () => pool.end(),
  $executeRaw: async (strings: TemplateStringsArray, ...values: any[]) => {
    const query = strings.reduce((acc, str, i) => acc + str + (values[i] ? `$${i + 1}` : ''), '');
    return pool.query(query, values);
  },
  $queryRaw: async <T>(strings: TemplateStringsArray, ...values: any[]): Promise<T> => {
    const query = strings.reduce((acc, str, i) => acc + str + (values[i] ? `$${i + 1}` : ''), '');
    const result = await pool.query(query, values);
    return result.rows as T;
  },
  $transaction: async (fn: () => Promise<any>) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await fn();
      await client.query('COMMIT');
      return result;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  },
};

export class PrismaClient {
  static findUnique = async (table: string, where: Record<string, any>) => {
    const keys = Object.keys(where);
    const values = Object.values(where);
    const query = `SELECT * FROM ${table} WHERE ${keys.map((k, i) => `${k} = $${i + 1}`).join(' AND ')} LIMIT 1`;
    const result = await pool.query(query, values);
    return result.rows[0] || null;
  };

  static findMany = async (table: string, where?: Record<string, any>, options?: { take?: number; skip?: number; orderBy?: Record<string, string> }) => {
    let query = `SELECT * FROM ${table}`;
    const values: any[] = [];
    
    if (where && Object.keys(where).length > 0) {
      const keys = Object.keys(where);
      const condition = keys.map((k, i) => {
        if (where[k] === undefined) return `${k} IS NULL`;
        if (typeof where[k] === 'object' && where[k] !== null && 'gte' in where[k]) {
          values.push(where[k].gte);
          return `${k} >= $${values.length}`;
        }
        if (typeof where[k] === 'object' && where[k] !== null && 'lte' in where[k]) {
          values.push(where[k].lte);
          return `${k} <= $${values.length}`;
        }
        values.push(where[k]);
        return `${k} = $${values.length}`;
      }).join(' AND ');
      query += ` WHERE ${condition}`;
    }
    
    if (options?.orderBy) {
      const orderKey = Object.keys(options.orderBy)[0];
      const orderDir = options.orderBy[orderKey];
      query += ` ORDER BY ${orderKey} ${orderDir}`;
    }
    
    if (options?.take) {
      query += ` LIMIT ${options.take}`;
    }
    
    if (options?.skip) {
      query += ` OFFSET ${options.skip}`;
    }
    
    const result = await pool.query(query, values);
    return result.rows;
  };

  static create = async (table: string, data: Record<string, any>) => {
    const keys = Object.keys(data);
    const values = Object.values(data);
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
    const query = `INSERT INTO ${table} (${keys.join(', ')}) VALUES (${placeholders}) RETURNING *`;
    const result = await pool.query(query, values);
    return result.rows[0];
  };

  static update = async (table: string, where: Record<string, any>, data: Record<string, any>) => {
    const whereKeys = Object.keys(where);
    const whereValues = Object.values(where);
    const dataKeys = Object.keys(data);
    const dataValues = Object.values(data);
    const setClause = dataKeys.map((k, i) => `${k} = $${i + 1}`).join(', ');
    const whereClause = whereKeys.map((k, i) => `${k} = $${dataValues.length + i + 1}`).join(' AND ');
    const query = `UPDATE ${table} SET ${setClause} WHERE ${whereClause} RETURNING *`;
    const result = await pool.query(query, [...dataValues, ...whereValues]);
    return result.rows[0];
  };

  static delete = async (table: string, where: Record<string, any>) => {
    const keys = Object.keys(where);
    const values = Object.values(where);
    const query = `DELETE FROM ${table} WHERE ${keys.map((k, i) => `${k} = $${i + 1}`).join(' AND ')} RETURNING *`;
    const result = await pool.query(query, values);
    return result.rows[0];
  };
}

const db = { prisma, Pool };
export default db;
