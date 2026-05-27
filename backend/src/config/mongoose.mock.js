const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DB_PATH = path.join(__dirname, 'db.json');

// Helper to load db
function loadDB() {
  if (!fs.existsSync(DB_PATH)) {
    fs.writeFileSync(DB_PATH, JSON.stringify({ Users: [], News: [], Bookmarks: [], Categories: [] }, null, 2));
  }
  try {
    return JSON.parse(fs.readFileSync(DB_PATH, 'utf-8'));
  } catch (err) {
    return { Users: [], News: [], Bookmarks: [], Categories: [] };
  }
}

// Helper to save db
function saveDB(data) {
  fs.writeFileSync(DB_PATH, JSON.stringify(data, null, 2));
}

// MongoDB Query Matcher
function matchQuery(doc, query) {
  if (!query || Object.keys(query).length === 0) return true;

  for (const key in query) {
    const val = query[key];

    if (key === '$or') {
      if (!Array.isArray(val)) return false;
      const matchAny = val.some(subQuery => matchQuery(doc, subQuery));
      if (!matchAny) return false;
      continue;
    }

    if (key === '$and') {
      if (!Array.isArray(val)) return false;
      const matchAll = val.every(subQuery => matchQuery(doc, subQuery));
      if (!matchAll) return false;
      continue;
    }

    if (key === '$text') {
      if (val && typeof val === 'object' && val.$search) {
        const searchStr = val.$search.toLowerCase();
        const docText = `${doc.title || ''} ${doc.description || ''} ${doc.content || ''}`.toLowerCase();
        if (!docText.includes(searchStr)) return false;
      }
      continue;
    }

    const docVal = doc[key];
    if (val && typeof val === 'object' && !Array.isArray(val)) {
      if (val instanceof RegExp) {
        if (!val.test(docVal ? docVal.toString() : '')) return false;
        continue;
      }
      if ('$regex' in val) {
        const regexStr = val.$regex;
        const options = val.$options || '';
        const regex = new RegExp(regexStr, options);
        if (!regex.test(docVal ? docVal.toString() : '')) return false;
        continue;
      }

      for (const op in val) {
        const opVal = val[op];
        if (op === '$gt') {
          if (!(new Date(docVal) > new Date(opVal))) return false;
        } else if (op === '$gte') {
          if (!(new Date(docVal) >= new Date(opVal))) return false;
        } else if (op === '$lt') {
          if (!(new Date(docVal) < new Date(opVal))) return false;
        } else if (op === '$lte') {
          if (!(new Date(docVal) <= new Date(opVal))) return false;
        } else if (op === '$ne') {
          if (docVal == opVal) return false;
        } else if (op === '$in') {
          if (!Array.isArray(opVal) || !opVal.includes(docVal)) return false;
        } else if (op === '$nin') {
          if (Array.isArray(opVal) && opVal.includes(docVal)) return false;
        } else if (op === '$exists') {
          const exists = (docVal !== undefined && docVal !== null);
          if (opVal !== exists) return false;
        }
      }
    } else {
      if (docVal !== val) {
        const strDocVal = (docVal !== undefined && docVal !== null) ? docVal.toString() : '';
        const strVal = (val !== undefined && val !== null) ? val.toString() : '';
        if (strDocVal !== strVal) return false;
      }
    }
  }

  return true;
}


const modelRegistry = {};

class MockQuery {
  constructor(collectionName, filter, isFindOne = false) {
    this.collectionName = collectionName;
    this.filter = filter;
    this.isFindOne = isFindOne;
    this._selectFields = null;
    this._populateFields = [];
    this._sortField = null;
    this._limitVal = null;
    this._skipVal = null;
  }

  select(fields) {
    this._selectFields = fields;
    return this;
  }

  populate(field, select) {
    if (typeof field === 'object') {
      this._populateFields.push(field);
    } else {
      this._populateFields.push({ field, select });
    }
    return this;
  }

  sort(field) {
    this._sortField = field;
    return this;
  }

  limit(val) {
    this._limitVal = val;
    return this;
  }

  skip(val) {
    this._skipVal = val;
    return this;
  }

  async execute() {
    const db = loadDB();
    const items = db[this.collectionName] || [];
    
    let results = items.filter(doc => matchQuery(doc, this.filter));

    if (this._sortField) {
      let isDesc = false;
      let field = this._sortField;
      if (field.startsWith('-')) {
        isDesc = true;
        field = field.substring(1);
      }
      results.sort((a, b) => {
        let valA = a[field];
        let valB = b[field];
        if (typeof valA === 'string') {
          return isDesc ? valB.localeCompare(valA) : valA.localeCompare(valB);
        }
        return isDesc ? valB - valA : valA - valB;
      });
    }

    if (this._skipVal !== null) {
      results = results.slice(this._skipVal);
    }
    if (this._limitVal !== null) {
      results = results.slice(0, this._limitVal);
    }

    const ModelClass = modelRegistry[this.collectionName];
    if (!ModelClass) {
      return this.isFindOne ? results[0] || null : results;
    }

    let docs = results.map(data => new ModelClass(data, false));

    for (const pop of this._populateFields) {
      const popField = typeof pop === 'string' ? pop : pop.field;
      const schema = ModelClass.schema;
      const pathInfo = schema.paths[popField];
      let refModelName = pathInfo ? pathInfo.ref : null;
      if (!refModelName) {
        const virtualInfo = schema.virtuals[popField];
        if (virtualInfo && virtualInfo.ref) {
          refModelName = virtualInfo.ref;
        }
      }

      if (refModelName) {
        const RefModel = modelRegistry[refModelName + 's'];
        if (RefModel) {
          for (const doc of docs) {
            const pathInfo = schema.paths[popField];
            if (pathInfo) {
              const refId = doc[popField];
              if (refId) {
                let refDoc;
                if (pop.select) {
                  refDoc = await RefModel.findById(refId).select(pop.select);
                } else {
                  refDoc = await RefModel.findById(refId);
                }
                doc[popField] = refDoc;
              }
            } else {
              const virtualInfo = schema.virtuals[popField];
              if (virtualInfo) {
                const foreignField = virtualInfo.foreignField;
                const localField = virtualInfo.localField;
                const localVal = doc[localField];
                if (localVal) {
                  const queryObj = {};
                  queryObj[foreignField] = localVal;
                  let refDocs;
                  if (pop.select) {
                    refDocs = await RefModel.find(queryObj).select(pop.select);
                  } else {
                    refDocs = await RefModel.find(queryObj);
                  }
                  if (virtualInfo.count) {
                    doc[popField] = refDocs.length;
                  } else {
                    doc[popField] = refDocs;
                  }
                }
              }
            }
          }
        }
      }
    }

    // Apply select projection rules to returned docs
    const schema = ModelClass.schema;
    if (schema) {
      // Find all fields marked with select: false in the schema definition
      const defaultExcludedFields = [];
      for (const key in schema.paths) {
        if (schema.paths[key] && schema.paths[key].select === false) {
          defaultExcludedFields.push(key);
        }
      }

      // Parse this._selectFields
      let selectFields = null;
      let excludeFields = null;
      let forceIncludeFields = [];

      if (typeof this._selectFields === 'string') {
        const parts = this._selectFields.trim().split(/\s+/);
        for (const part of parts) {
          if (part.startsWith('-')) {
            if (!excludeFields) excludeFields = [];
            excludeFields.push(part.substring(1));
          } else if (part.startsWith('+')) {
            forceIncludeFields.push(part.substring(1));
          } else {
            if (!selectFields) selectFields = [];
            selectFields.push(part);
          }
        }
      } else if (this._selectFields && typeof this._selectFields === 'object') {
        for (const key in this._selectFields) {
          const val = this._selectFields[key];
          if (val === 0 || val === false) {
            if (!excludeFields) excludeFields = [];
            excludeFields.push(key);
          } else if (val === 1 || val === true) {
            if (!selectFields) selectFields = [];
            selectFields.push(key);
          }
        }
      }

      // Filter properties of each doc
      for (const doc of docs) {
        if (selectFields) {
          // Inclusion projection
          const keysToKeep = new Set([
            '_id', 'id', 'createdAt', 'updatedAt',
            ...selectFields,
            ...forceIncludeFields,
            ...Object.keys(schema.virtuals || {}),
            ...this._populateFields.map(p => typeof p === 'string' ? p : p.field)
          ]);
          for (const key in doc) {
            if (typeof doc[key] !== 'function' && !key.startsWith('_') && !keysToKeep.has(key)) {
              delete doc[key];
            }
          }
        } else {
          // Exclusion projection (defaultExcludedFields + explicit exclusions)
          const keysToRemove = new Set(excludeFields || []);
          for (const field of defaultExcludedFields) {
            if (!forceIncludeFields.includes(field)) {
              keysToRemove.add(field);
            }
          }
          for (const key of keysToRemove) {
            delete doc[key];
          }
        }
      }
    }

    if (this.isFindOne) {
      return docs[0] || null;
    }
    return docs;
  }

  then(onFulfilled, onRejected) {
    return this.execute().then(onFulfilled, onRejected);
  }
}

class Schema {
  constructor(paths, options) {
    this.paths = paths || {};
    this.options = options || {};
    this.methods = {};
    this.statics = {};
    this.virtuals = {};
    this._preHooks = { save: [] };
  }

  virtual(name, options) {
    this.virtuals[name] = options;
    return {
      get(fn) { return this; },
      set(fn) { return this; }
    };
  }

  index(fields, options) {
    return this;
  }

  pre(event, fn) {
    if (!this._preHooks[event]) {
      this._preHooks[event] = [];
    }
    this._preHooks[event].push(fn);
  }
}

const SchemaTypes = {
  ObjectId: 'ObjectId'
};

function createModelClass(modelName, schema) {
  const collectionName = modelName + 's';

  class MockDocument {
    constructor(data, isNew = true) {
      const proxy = new Proxy(this, {
        set(target, prop, value) {
          if (schema.paths[prop] || prop === 'password') {
            target._modifiedPaths.add(prop);
          }
          target[prop] = value;
          return true;
        }
      });

      for (const methodName in schema.methods) {
        this[methodName] = schema.methods[methodName].bind(proxy);
      }

      this._id = data._id || data.id || crypto.randomUUID();
      this.createdAt = data.createdAt || new Date().toISOString();
      this.updatedAt = data.updatedAt || new Date().toISOString();

      this._modifiedPaths = new Set();
      if (isNew) {
        this._isNew = true;
        for (const key in data) {
          this._modifiedPaths.add(key);
        }
      } else {
        this._isNew = false;
      }

      for (const key in data) {
        if (key !== 'id') {
          this[key] = data[key];
        }
      }

      // Apply schema defaults if undefined
      for (const pathKey in schema.paths) {
        const pathDef = schema.paths[pathKey];
        if (this[pathKey] === undefined && pathDef) {
          if (pathDef.default !== undefined) {
            let defaultValue;
            if (typeof pathDef.default === 'function') {
              if (pathDef.default === Date.now) {
                defaultValue = new Date().toISOString();
              } else {
                defaultValue = pathDef.default();
              }
            } else {
              defaultValue = pathDef.default;
            }
            this[pathKey] = defaultValue;
            if (isNew) {
              this._modifiedPaths.add(pathKey);
            }
          }
        }
      }

      return proxy;
    }

    isModified(path) {
      if (this._isNew) return true;
      return this._modifiedPaths.has(path);
    }

    set(path, value) {
      this[path] = value;
      this._modifiedPaths.add(path);
    }

    async save() {
      const hooks = schema._preHooks.save || [];
      for (const hook of hooks) {
        await new Promise((resolve, reject) => {
          hook.call(this, (err) => {
            if (err) reject(err);
            else resolve();
          });
        });
      }

      const db = loadDB();
      const items = db[collectionName] || [];

      const plainObj = { ...this };
      for (const key in plainObj) {
        if (
          typeof plainObj[key] === 'function' || 
          (key.startsWith('_') && key !== '_id') || 
          plainObj[key] === undefined
        ) {
          delete plainObj[key];
        }
      }

      for (const key in plainObj) {
        const pathInfo = schema.paths[key];
        if (pathInfo && pathInfo.type === 'ObjectId' && plainObj[key] && typeof plainObj[key] === 'object') {
          plainObj[key] = plainObj[key]._id || plainObj[key].id;
        }
      }

      const existingIndex = items.findIndex(item => item._id === this._id);
      this.updatedAt = new Date().toISOString();
      plainObj.updatedAt = this.updatedAt;

      if (existingIndex !== -1) {
        items[existingIndex] = { ...items[existingIndex], ...plainObj };
      } else {
        items.push(plainObj);
      }

      db[collectionName] = items;
      saveDB(db);
      this._isNew = false;
      this._modifiedPaths.clear();
      return this;
    }

    toObject() {
      const obj = { ...this };
      obj.id = this._id;
      delete obj._isNew;
      delete obj._modifiedPaths;
      return obj;
    }

    toJSON() {
      return this.toObject();
    }
  }

  for (const staticName in schema.statics) {
    MockDocument[staticName] = schema.statics[staticName];
  }

  MockDocument.schema = schema;

  MockDocument.find = function(query) {
    return new MockQuery(collectionName, query, false);
  };

  MockDocument.findOne = function(query) {
    return new MockQuery(collectionName, query, true);
  };

  MockDocument.findById = function(id) {
    return new MockQuery(collectionName, { _id: id }, true);
  };

  MockDocument.create = async function(data) {
    const doc = new MockDocument(data, true);
    await doc.save();
    return doc;
  };

  MockDocument.findByIdAndUpdate = async function(id, updates, options) {
    const doc = await MockDocument.findById(id);
    if (!doc) return null;

    const setUpdates = updates.$set || updates;
    for (const key in setUpdates) {
      if (!key.startsWith('$')) {
        doc.set(key, setUpdates[key]);
      }
    }

    if (updates.$addToSet) {
      for (const key in updates.$addToSet) {
        const val = updates.$addToSet[key];
        if (!Array.isArray(doc[key])) {
          doc[key] = [];
        }
        if (!doc[key].includes(val)) {
          doc[key].push(val);
        }
        doc._modifiedPaths.add(key);
      }
    }

    if (updates.$pull) {
      for (const key in updates.$pull) {
        const val = updates.$pull[key];
        if (Array.isArray(doc[key])) {
          doc[key] = doc[key].filter(item => item.toString() !== val.toString());
        }
        doc._modifiedPaths.add(key);
      }
    }

    await doc.save();
    return doc;
  };

  MockDocument.updateMany = async function(query, updates) {
    const db = loadDB();
    const items = db[collectionName] || [];
    let updatedCount = 0;

    const setUpdates = updates.$set || updates;

    const updatedItems = items.map(item => {
      if (matchQuery(item, query)) {
        updatedCount++;
        const doc = new MockDocument(item, false);
        for (const key in setUpdates) {
          if (!key.startsWith('$')) {
            doc.set(key, setUpdates[key]);
          }
        }
        if (updates.$addToSet) {
          for (const key in updates.$addToSet) {
            const val = updates.$addToSet[key];
            if (!Array.isArray(doc[key])) doc[key] = [];
            if (!doc[key].includes(val)) doc[key].push(val);
          }
        }
        if (updates.$pull) {
          for (const key in updates.$pull) {
            const val = updates.$pull[key];
            if (Array.isArray(doc[key])) {
              doc[key] = doc[key].filter(i => i.toString() !== val.toString());
            }
          }
        }
        const plainObj = { ...doc };
        for (const k in plainObj) {
          if (typeof plainObj[k] === 'function' || (k.startsWith('_') && k !== '_id')) {
            delete plainObj[k];
          }
        }
        plainObj.updatedAt = new Date().toISOString();
        return plainObj;
      }
      return item;
    });

    db[collectionName] = updatedItems;
    saveDB(db);
    return { matchedCount: updatedCount, modifiedCount: updatedCount };
  };

  MockDocument.findByIdAndDelete = async function(id) {
    const db = loadDB();
    const items = db[collectionName] || [];
    const index = items.findIndex(item => item._id === id);
    if (index !== -1) {
      const deleted = items.splice(index, 1);
      db[collectionName] = items;
      saveDB(db);
      return new MockDocument(deleted[0], false);
    }
    return null;
  };

  MockDocument.countDocuments = async function(query) {
    const db = loadDB();
    const items = db[collectionName] || [];
    return items.filter(doc => matchQuery(doc, query)).length;
  };

  MockDocument.deleteMany = async function(query) {
    const db = loadDB();
    const items = db[collectionName] || [];
    const remaining = items.filter(doc => !matchQuery(doc, query));
    db[collectionName] = remaining;
    saveDB(db);
    return { deletedCount: items.length - remaining.length };
  };

  MockDocument.insertMany = async function(arr) {
    const docs = [];
    for (const item of arr) {
      const doc = await MockDocument.create(item);
      docs.push(doc);
    }
    return docs;
  };

  modelRegistry[collectionName] = MockDocument;
  return MockDocument;
}

const mongoose = {
  Schema: Schema,
  model: createModelClass,
  Types: {
    ObjectId: (id) => id || crypto.randomUUID()
  },
  connect: async (uri) => {
    console.log("📝 Connected to In-Memory JSON file-based database.");
    return { connection: { host: 'json-file-db' } };
  }
};

Schema.Types = SchemaTypes;
mongoose.Schema.Types = SchemaTypes;

module.exports = mongoose;
