-- 库存记录表：每次进货/出货一条记录
CREATE TABLE inventory_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id),
  type TEXT NOT NULL CHECK (type IN ('in', 'out')),
  quantity NUMERIC(10,2) NOT NULL,
  note TEXT DEFAULT '',
  related_order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE inventory_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON inventory_records FOR ALL USING (true);
ALTER PUBLICATION supabase_realtime ADD TABLE inventory_records;