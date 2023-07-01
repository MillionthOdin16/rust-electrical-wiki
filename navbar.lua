
traverse = 'topdown'

Indent = -1

function BulletList (blist)

	local function Foreach ( out, elem, func, path)
		Indent = Indent + 1
		local list = pandoc.Inlines( foldlist(Indent, 1) )
		for i, item in ipairs( elem.content ) do
			func( list, item, path )
		end
		Indent = Indent - 1
		list:insert( closespan() )
		if out then out:extend( list ) end
		return list
	end

	local function ParseTocEntry(out, items, path )
		local item = items[1].content[1]
		local text = pandoc.utils.stringify( item )
		local link = path .. item.target
		if #items == 1 then
			out:insert( linkline( text, link ) )
		else
			out:insert( linkline( text, link ) )
 			Foreach( out, items[2], ParseTocEntry, path )
		end
	end

	local function ParseBarEntry( out, item )
		local text = pandoc.utils.stringify( item[1] )
		if item[1].content[1].t == 'Link' then
			local htmlpath = item[1].content[1].target
			local mdpath = 'content/' .. htmlpath:gsub("html","md")
			out:insert( foldlink(text, htmlpath) )
			Foreach( out, FileToc(mdpath), ParseTocEntry, htmlpath )
		else
			out:insert( foldable(text) )
			Foreach( out, item[2], ParseBarEntry )
		end
	end

	return Foreach( nil, blist, ParseBarEntry )
end

function ReadFile ( path )
	local file = assert(io.open(path, "r"), "Cannot open file '" .. path .. "'\n" )
	local str = file:read("*all")
	local doc = pandoc.read( str, 'markdown')
	return doc
end

function FileToc ( path )
	return pandoc.structure.table_of_contents( ReadFile( path ) )
end

function foldable (text) return pandoc.RawInline('html', [[
<span class="sideline foldable folded unfoldonload" onclick="toggfold(this);">
	<span class="sidetext"> ]] .. text .. [[ </span>
	<span class="sidesign"></span>
</span>
]] ) end

function foldlink (text, url) return pandoc.RawInline('html', [[
	<span class='sideline foldable folded' onclick='toggfold(this);'>
		<a class='sidetext' onclick='preventbubble(event);'
		href=']] .. url .. [['> ]] .. text .. [[ </a>
		<span class='sidesign'></span>
	</span>
]] ) end

function linkline (text, url) return pandoc.RawInline('html', [[
		<a class='sideline' href=']] .. url .. [['>
			<span class='sidetext'> ]] .. text .. [[ </span>
			<span class='sidesign'></span>
		</a>
]] ) end

function foldlist (indentlvl, folded) return pandoc.RawInline('html',
	'  <span class="sidelist indent' .. indentlvl .. ' folded">' )
end

function closespan () return pandoc.RawInline('html', '  </span>' ) end

