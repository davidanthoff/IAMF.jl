module IAMF

if VERSION < v"0.4.0-dev"
    using Docile
end
@docstrings

include("metainfo.jl")
using DataStructures
using DataFrames

export
	ComponentState, timestep, run, @defcomp, Model, setindex, addcomponent, setparameter,
	connectparameter, setleftoverparameters, getvariable, adder, MarginalModel, getindex,
	getdataframe, components, variables

abstract ComponentState

type Model
	indices_counts::Dict{Symbol,Int}
	indices_values::Dict{Symbol,Vector{Any}}
	components::OrderedDict{Symbol,ComponentState}
	parameters_that_are_set::Set{String}

	function Model()
		m = new()
		m.indices_counts = Dict{Symbol,Int}()
		m.indices_values = Dict{Symbol, Vector{Any}}()
		m.components = OrderedDict{Symbol,ComponentState}()
		m.parameters_that_are_set = Set{String}()
		return m
	end
end

type MarginalModel
	base::Model
	marginal::Model
	delta::Float64
end

"""
List all the components in a given model.
"""
function components(m::Model)
	collect(keys(m.components))
end

"""
List all the variables in a component.
"""
function variables(m::Model, componentname::Symbol)
	meta = metainfo.getallcomps()
	c = meta[typeof(m.components[componentname])]
	collect(keys(c.variables))
end

function getindex(m::MarginalModel, component::Symbol, name::Symbol)
	return (m.marginal[component,name].-m.base[component,name])./m.delta
end

function setindex(m::Model, name::Symbol, count::Int)
	m.indices_counts[name] = count
	m.indices_values[name] = [1:count]
	nothing
end

function setindex{T}(m::Model, name::Symbol, values::Vector{T})
	m.indices_counts[name] = length(values)
	m.indices_values[name] = copy(values)
	nothing
end

function addcomponent(m::Model, t, name::Symbol;before=nothing,after=nothing)
	if before!=nothing && after!=nothing
		error("Can only specify before or after parameter")
	end

	comp = t(m.indices_counts)

	if before!=nothing
		newcomponents = OrderedDict{Symbol,ComponentState}()
		for i in keys(m.components)
			if i==before
				newcomponents[name] = comp
			end
			newcomponents[i] = m.components[i]
		end
		m.components = newcomponents
	elseif after!=nothing
		error("Not yet implemented")
	else
		m.components[name] = comp
	end
	nothing
end

function addcomponent(m::Model, t;before=nothing,after=nothing)
	addcomponent(m,t,symbol(string(t)),before=before,after=after)
	nothing
end

"""
Add a component to a model.
"""
addcomponent

"""
Set the parameter of a component in a model to a given value.
"""
function setparameter(m::Model, component::Symbol, name::Symbol, value)
	c = m.components[component]
	setfield!(c.Parameters,name,value)
	push!(m.parameters_that_are_set, string(component) * string(name))
	nothing
end

function connectparameter(m::Model, component::Symbol, name::Symbol, source::Symbol)
	connectparameter(m, component, name, source, name)
end

function connectparameter(m::Model, target_component::Symbol, target_name::Symbol, source_component::Symbol, source_name::Symbol)
	c_target = m.components[target_component]
	c_source = m.components[source_component]
	setfield!(c_target.Parameters, target_name, getfield(c_source.Variables, source_name))
	push!(m.parameters_that_are_set, string(target_component) * string(target_name))
	nothing
end

"""
Bind the parameter of one component to a variable in another component.

"""
connectparameter

"""
Set all the parameters in a model that don't have a value and are not connected
to some other component to a value from a dictionary.
"""
function setleftoverparameters(m::Model,parameters::Dict{Any,Any})
	for c in m.components
		for name in names(c[2].Parameters)
			if !in(string(c[1])*string(name), m.parameters_that_are_set)
				setfield!(c[2].Parameters,name,parameters[lowercase(string(name))])
			end
		end
	end
	nothing
end

function getindex(m::Model, component::Symbol, name::Symbol)
	return getfield(m.components[component].Variables, name)
end

"""
Return the values for a variable as a DataFrame.
"""
function getdataframe(m::Model, component::Symbol, name::Symbol)
	comp_type = typeof(m.components[component])
	vardiminfo = getdiminfoforvar(typeof(m.components[component]), name)
	if length(vardiminfo)==0
		return m[component, name]
	elseif length(vardiminfo)==1
		df = DataFrame()
		df[vardiminfo[1]] = m.indices_values[vardiminfo[1]]
		df[name] = m[component, name]
		return df
	elseif length(vardiminfo)==2
		df = DataFrame()
		dim1 = length(m.indices_values[vardiminfo[1]])
		dim2 = length(m.indices_values[vardiminfo[2]])
		df[vardiminfo[1]] = repeat(m.indices_values[vardiminfo[1]],inner=[dim2])
		df[vardiminfo[2]] = repeat(m.indices_values[vardiminfo[2]],outer=[dim1])
		data = m[component, name]
		df[name] = cat(1,[vec(data[i,:]) for i=1:dim1]...)
		return df
	else
		error("Not yet implemented")
	end
end

import Base.show
show(io::IO, a::ComponentState) = print(io, "ComponentState")

"""
Run the model once.
"""
function run(m::Model;ntimesteps=typemax(Int64))

	for c in values(m.components)
		resetvariables(c)
		init(c)
	end

	for t=1:min(m.indices_counts[:time],ntimesteps)
		for c in values(m.components)
			timestep(c,t)
		end
	end
end

function timestep(s, t::Int)
	typeofs = typeof(s)
	println("Generic timestep called for $typeofs.")
end

function init(s)
end

function resetvariables(s)
	typeofs = typeof(s)
	println("Generic resetvariables called for $typeofs.")
end

function getdiminfoforvar(s, name)
	meta = metainfo.getallcomps()
	meta[s].variables[name].dimensions
end

"""
Define a new component.
"""
macro defcomp(name, ex)
	dimdef = Expr(:block)
	dimconstructor = Expr(:block)

	pardef = Expr(:block)

	vardef = Expr(:block)
	varalloc = Expr(:block)
	resetvarsdef = Expr(:block)

	metavardef = Expr(:block)

	for line in ex.args
		if line.head==:(=) && line.args[2].head==:call && line.args[2].args[1]==:Index
			dimensionName = line.args[1]

			push!(dimdef.args,:($(esc(dimensionName))::$(esc(UnitRange{Int64}))))
			push!(dimconstructor.args,:(s.$(dimensionName) = UnitRange{Int64}(1,indices[$(QuoteNode(dimensionName))])))
		elseif line.head==:(=) && line.args[2].head==:call && line.args[2].args[1]==:Parameter
			if isa(line.args[1], Symbol)
				parameterName = line.args[1]
				parameterType = :Float64
			elseif line.args[1].head==:(::)
				parameterName = line.args[1].args[1]
				parameterType = line.args[1].args[2]
			else
				error()
			end

			if any(l->isa(l,Expr) && l.head==:kw && l.args[1]==:index,line.args[2].args)
				parameterIndex = first(filter(l->isa(l,Expr) && l.head==:kw && l.args[1]==:index,line.args[2].args)).args[2].args
				partypedef = :(Array{$(parameterType),$(length(parameterIndex))})
			else
				partypedef = parameterType
			end

			push!(pardef.args,:($(esc(parameterName))::$(esc(partypedef))))
		elseif line.head==:(=) && line.args[2].head==:call && line.args[2].args[1]==:Variable
			if isa(line.args[1], Symbol)
				variableName = line.args[1]
				variableType = :Float64
			elseif line.args[1].head==:(::)
				variableName = line.args[1].args[1]
				variableType = line.args[1].args[2]
			else
				error()
			end

			if any(l->isa(l,Expr) && l.head==:kw && l.args[1]==:index,line.args[2].args)
				variableIndex = first(filter(l->isa(l,Expr) && l.head==:kw && l.args[1]==:index,line.args[2].args)).args[2].args
				vartypedef = :(Array{$(variableType),$(length(variableIndex))})

				vardims = Array(Any, 0)
				u = :(temp_indices = [])
				for l in variableIndex
					if isa(l, Symbol)
						push!(u.args[2].args, :(indices[$(QuoteNode(l))]))
					elseif isa(l, Int)
						push!(u.args[2].args, l)
					else
						error()
					end
					push!(vardims, l)
				end
				push!(metavardef.args, :(metainfo.addvariable($(esc(name)), $(QuoteNode(variableName)), $(esc(variableType)), $(vardims), "", "")))

				push!(varalloc.args,u)
				push!(varalloc.args,:(s.$(variableName) = Array($(variableType),temp_indices...)))

				push!(resetvarsdef.args,:($(esc(symbol("fill!")))(s.Variables.$(variableName),$(esc(symbol("NaN"))))))
			else
				vartypedef = variableType
				push!(metavardef.args, :(metainfo.addvariable($(esc(name)), $(QuoteNode(variableName)), $(esc(variableType)), {}, "", "")))

				push!(resetvarsdef.args,:(s.Variables.$(variableName) = $(esc(symbol("NaN")))))
			end

			push!(vardef.args,:($(esc(variableName))::$(esc(vartypedef))))

		elseif line.head==:line
		else
			error("Unknown expression.")
		end
	end

	x = quote

		type $(symbol(string(name,"Parameters")))
			$(pardef)

			function $(esc(symbol(string(name,"Parameters"))))()
				$(esc(:s)) = new()
				return $(esc(:s))
			end
		end

		type $(symbol(string(name,"Variables")))
			$(vardef)

			function $(esc(symbol(string(name, "Variables"))))(indices)
				$(esc(:indices)) = indices
				$(esc(:s)) = new()
				$(esc(varalloc))
				return $(esc(:s))
			end
		end

		type $(symbol(string(name,"Dimensions")))
			$(dimdef)

			function $(esc(symbol(string(name,"Dimensions"))))(indices)
				$(esc(:indices)) = indices
				$(esc(:s)) = new()
				$(esc(dimconstructor))
				return $(esc(:s))
			end
		end

		type $(esc(symbol(name))) <: IAMF.ComponentState
			nsteps::Int
			Parameters::$(esc(symbol(string(name,"Parameters"))))
			Variables::$(esc(symbol(string(name,"Variables"))))
			Dimensions::$(esc(symbol(string(name,"Dimensions"))))

			function $(esc(symbol(name)))(indices)
				s = new()
				s.nsteps = indices[:time]
				s.Parameters = $(esc(symbol(string(name,"Parameters"))))()
				s.Dimensions = $(esc(symbol(string(name,"Dimensions"))))(indices)
				s.Variables = $(esc(symbol(string(name,"Variables"))))(indices)
				return s
			end
		end

		import IAMF.timestep
		import IAMF.init
		import IAMF.resetvariables

		function $(esc(symbol("resetvariables")))(s::$(esc(symbol(name))))
			$(resetvarsdef)
		end

		metainfo.addcomponent($(esc(symbol(name))))
		$(metavardef)
	end

	x
end

@defcomp adder begin
    add = Parameter(index=[time])
    input = Parameter(index=[time])
    output = Variable(index=[time])
end

function timestep(s::adder, t::Int)
    v = s.Variables
    p = s.Parameters

    v.output[t] = p.input[t] + p.add[t]
end

end # module
