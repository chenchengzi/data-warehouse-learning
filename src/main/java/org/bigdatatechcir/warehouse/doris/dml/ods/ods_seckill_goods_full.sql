-- DROP TABLE IF EXISTS ods.ods_seckill_goods_full;
CREATE TABLE ods.ods_seckill_goods_full
(
    `id`           VARCHAR(255) COMMENT '编号',
    `k1`           DATE NOT NULL COMMENT '分区字段',
    `spu_id`       STRING COMMENT 'spu_id',
    `sku_id`       STRING COMMENT 'sku_id',
    `sku_name`     STRING COMMENT 'sku名称',
    `sku_default_img` STRING COMMENT '商品图片',
    `price`        DECIMAL(16, 2) COMMENT '商品原价格',
    `cost_price`   DECIMAL(16, 2) COMMENT '商品秒杀价格',
    `create_time`  STRING COMMENT '创建时间',
    `check_time`   STRING COMMENT '审核时间',
    `status`       STRING COMMENT '审核状态',
    `start_time`   STRING COMMENT '开始时间',
    `end_time`     STRING COMMENT '结束时间',
    `num`          BIGINT COMMENT '秒杀商品数',
    `stock_count`  BIGINT COMMENT '剩余库存数',
    `sku_desc`     STRING COMMENT '描述'
)
    ENGINE=OLAP  -- 使用Doris的OLAP引擎，适用于高并发分析场景
    UNIQUE KEY(`id`,`k1`)  -- 唯一键约束，保证(id, k1)组合的唯一性（Doris聚合模型特性）
COMMENT '秒杀商品表'
PARTITION BY RANGE(`k1`) ()  -- 按日期范围分区（具体分区规则由动态分区配置决定）
DISTRIBUTED BY HASH(`id`)  -- 按id哈希分桶，保证相同id的数据分布在同一节点
PROPERTIES
(
    "replication_allocation" = "tag.location.default: 1",  -- 副本分配策略：默认标签分配1个副本
    "is_being_synced" = "false",          -- 是否处于同步状态（通常保持false）
    "storage_format" = "V2",             -- 存储格式版本（V2支持更高效压缩和索引）
    "light_schema_change" = "true",      -- 启用轻量级schema变更（仅修改元数据，无需数据重写）
    "disable_auto_compaction" = "false", -- 启用自动压缩（合并小文件提升查询性能）
    "enable_single_replica_compaction" = "false", -- 禁用单副本压缩（多副本时保持数据一致性）

    "dynamic_partition.enable" = "true",            -- 启用动态分区
    "dynamic_partition.time_unit" = "DAY",          -- 按天创建分区
    "dynamic_partition.start" = "-60",             -- 保留最近60天的历史分区
    "dynamic_partition.end" = "3",                 -- 预先创建未来3天的分区
    "dynamic_partition.prefix" = "p",              -- 分区名前缀（如p20240101）
    "dynamic_partition.buckets" = "32",            -- 每个分区的分桶数（影响并行度）
    "dynamic_partition.create_history_partition" = "true", -- 自动创建缺失的历史分区

    "bloom_filter_columns" = "id,sku_id,spu_id",  -- 为高频过滤字段创建布隆过滤器，加速WHERE查询
    "compaction_policy" = "time_series",          -- 按时间序合并策略优化时序数据
    "enable_unique_key_merge_on_write" = "true",  -- 唯一键写时合并（实时更新场景减少读放大）
    "in_memory" = "false"                        -- 关闭全内存存储（仅小表可开启）
); 