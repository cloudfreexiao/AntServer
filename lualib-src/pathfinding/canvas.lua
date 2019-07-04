local canvas = {}
canvas.__index = canvas

local temp = [[
<html>
<body>
<canvas id="myCanvas">your browser does not support the canvas tag </canvas>
<script type="text/javascript">
var canvas=document.getElementById('myCanvas');
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;
var ctx=canvas.getContext('2d');
$CONTENT
</script>
</body>
</html>
]]

function canvas.new()
	return setmetatable({} , canvas)
end

function canvas:html()
	local t = { CONTENT = table.concat(self, "\n") }
	return (string.gsub(temp,"%$(%u+)", t))
end

function canvas:line(x1,y1,x2,y2)
	table.insert(self, (string.gsub([[
	ctx.beginPath();
	ctx.moveTo($x1,$y1);
	ctx.lineTo($x2,$y2);
	ctx.stroke();
]], "%$(%w+)", {
	x1 = x1,
	x2 = x2,
	y1 = y1,
	y2 = y2,
})))
end

function canvas:rect(x,y,w,h,c)
	if c then
		table.insert(self, "ctx.fillStyle = '" .. c .. "';")
	end
	table.insert(self, string.format("ctx.fillRect(%d,%d,%d,%d);",x,y,w,h))
end

return canvas
