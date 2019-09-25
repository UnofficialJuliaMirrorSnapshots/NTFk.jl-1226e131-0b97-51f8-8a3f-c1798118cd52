import DocumentFunction

function functions(re::Regex; stdout::Bool=false, quiet::Bool=false)
	n = 0
	for i in modules
		Core.eval(NTFk, :(@tryimport $(Symbol(i))))
		n += functions(Symbol(i), re; stdout=stdout, quiet=quiet)
	end
	n > 0 && string == "" && @info("Total number of functions: $n")
	return
end
function functions(string::String=""; stdout::Bool=false, quiet::Bool=false)
	n = 0
	for i in modules
		Core.eval(NTFk, :(@tryimport $(Symbol(i))))
		n += functions(Symbol(i), string; stdout=stdout, quiet=quiet)
	end
	n > 0 && string == "" && @info("Total number of functions: $n")
	return
end
function functions(m::Union{Symbol, Module}, re::Regex; stdout::Bool=false, quiet::Bool=false)
	n = 0
	try
		f = names(eval(m), true)
		functions = Array{String}(undef, 0)
		for i in 1:length(f)
			functionname = "$(f[i])"
			if occursin("eval", functionname) || occursin("#", functionname) || occursin("__", functionname) || functionname == "$m"
				continue
			end
			if ismatch(re, functionname)
				push!(functions, functionname)
			end
		end
		if length(functions) > 0
			!quiet && @info("$(m) functions:")
			sort!(functions)
			n = length(functions)
			if stdout
				!quiet && Base.display(TextDisplay(STDOUT), functions)
			else
				!quiet && Base.display(functions)
			end
		end
	catch
		@warn("Module $m not defined!")
	end
	n > 0 && string == "" && @info("Number of functions in module $m: $n")
	return n
end
function functions(m::Union{Symbol, Module}, string::String=""; stdout::Bool=false, quiet::Bool=false)
	n = 0
	if string != ""
		quiet=false
	end
	try
		f = names(Core.eval(NTFk, m); all=true)
		functions = Array{String}(undef, 0)
		for i in 1:length(f)
			functionname = "$(f[i])"
			if occursin("eval", functionname) || occursin("#", functionname) || occursin("__", functionname) || functionname == "$m"
				continue
			end
			if string == "" || occursin(string, functionname)
				push!(functions, functionname)
			end
		end
		if length(functions) > 0
			!quiet && @info("$(m) functions:")
			sort!(functions)
			n = length(functions)
			if stdout
				!quiet && Base.display(TextDisplay(STDOUT), functions)
			else
				!quiet && Base.display(functions)
			end
		end
	catch
		@warn("Module $m not defined!")
	end
	n > 0 && string == "" && @info("Number of functions in module $m: $n")
	return n
end
@doc """
List available functions in the NTFk modules:

$(DocumentFunction.documentfunction(functions;
argtext=Dict("string"=>"string to display functions with matching names",
			"m"=>"NTFk module")))

Examples:

```julia
NTFk.functions()
NTFk.functions("get")
NTFk.functions(NTFk, "get")
```
""" functions

"Checks if package is available"
function ispkgavailable(modulename::String; quiet::Bool=false)
	flag=false
	try
		Pkg.available(modulename)
		if typeof(Pkg.installed(modulename)) == Nothing
			flag=false
			!quiet && @info("Module $modulename is not available")
		else
			flag=true
		end
	catch
		!quiet && @info("Module $modulename is not available")
	end
	return flag
end

"Print error message"
function printerrormsg(errmsg::Any)
	Base.showerror(Base.stderr, errmsg)
	try
		if in(:msg, fieldnames(errmsg))
			@warn(strip(errmsg.msg))
		elseif typeof(errmsg) <: AbstractString
			@warn(errmsg)
		end
	catch
		@warn(errmsg)
	end
end

"Try to import a module"
macro tryimport(s::Symbol)
	mname = string(s)
	importq = string(:(import $s))
	infostring = string("Module ", s, " is not available")
	warnstring = string("Module ", s, " cannot be imported")
	q = quote
		try
			eval(Meta.parse($importq))
		catch errmsg
			printerrormsg(errmsg)
			@warn($warnstring)
		end
	end
	return :($(esc(q)))
end