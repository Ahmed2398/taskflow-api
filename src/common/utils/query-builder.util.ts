import { PaginatedResponse } from '../interfaces/paginated-response.interface.js';

export class QueryBuilder {
  /**
   * Build search conditions for Prisma (OR conditions)
   */
  static buildSearchConditions(search: string | undefined, fields: string[]) {
    if (!search) return undefined;

    return {
      OR: fields.map(field => ({
        [field]: {
          contains: search,
          mode: 'insensitive' as const,
        },
      })),
    };
  }

  /**
   * Build filter conditions for Prisma (AND conditions)
   */
  static buildFilterConditions(filters: Record<string, any>) {
    const conditions: any = {};

    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        // Handle date range filters
        if (key.endsWith('After')) {
          const field = key.replace('After', '');
          conditions[field] = { ...conditions[field], gte: new Date(value) };
        } else if (key.endsWith('Before')) {
          const field = key.replace('Before', '');
          conditions[field] = { ...conditions[field], lte: new Date(value) };
        } else {
          conditions[key] = value;
        }
      }
    });

    return conditions;
  }

  /**
   * Build sort options for Prisma
   */
  static buildSortOptions(sortBy?: string, sortOrder: 'asc' | 'desc' = 'desc') {
    if (!sortBy) return { createdAt: sortOrder };
    return { [sortBy]: sortOrder };
  }

  /**
   * Build pagination options for Prisma
   */
  static buildPaginationOptions(page: number = 1, limit: number = 10) {
    const skip = (page - 1) * limit;
    return { skip, take: limit };
  }

  /**
   * Build paginated response with metadata
   */
  static buildPaginatedResponse<T>(
    data: T[],
    total: number,
    page: number,
    limit: number,
  ): PaginatedResponse<T> {
    const totalPages = Math.ceil(total / limit);
    
    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }
}
