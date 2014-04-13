local abc = PriorityQueue()

abc:enqueue("b", 0.6)
abc:enqueue("a1", 0.3)
abc:enqueue("c1", 0.9)
abc:enqueue("a2", 0.3)
abc:dequeue()
abc:enqueue("c2", 0.9)
abc:enqueue("c3", 0.9)

local res = abc:dequeue()
while res ~= nil do
	print(res)
	res = abc:dequeue()
end