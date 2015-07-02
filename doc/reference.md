# IAMF


---

<a id="function__addcomponent.1" class="lexicon_definition"></a>
#### addcomponent [¶](#function__addcomponent.1)
Add a component to a model.


*source:*
[IAMF\src\IAMF.jl:105](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

---

<a id="function__bindparameter.1" class="lexicon_definition"></a>
#### bindparameter [¶](#function__bindparameter.1)
Bind the parameter of one component to a variable in another component.



*source:*
[IAMF\src\IAMF.jl:133](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

---

<a id="method__components.1" class="lexicon_definition"></a>
#### components(m::Model) [¶](#method__components.1)
List all the components in a given model.


*source:*
[IAMF\src\IAMF.jl:44](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

---

<a id="method__getdataframe.1" class="lexicon_definition"></a>
#### getdataframe(m::Model, component::Symbol, name::Symbol) [¶](#method__getdataframe.1)
Return the values for a variable as a DataFrame.


*source:*
[IAMF\src\IAMF.jl:157](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

---

<a id="method__run.1" class="lexicon_definition"></a>
#### run(m::Model) [¶](#method__run.1)
Run the model once.


*source:*
[IAMF\src\IAMF.jl:187](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

---

<a id="method__setleftoverparameters.1" class="lexicon_definition"></a>
#### setleftoverparameters(m::Model, parameters::Dict{Any, Any}) [¶](#method__setleftoverparameters.1)
Set all the parameters in a model that don't have a value and are not connected
to some other component to a value from a dictionary.


*source:*
[IAMF\src\IAMF.jl:139](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

---

<a id="method__setparameter.1" class="lexicon_definition"></a>
#### setparameter(m::Model, component::Symbol, name::Symbol, value) [¶](#method__setparameter.1)
Set the parameter of a component in a model to a given value.


*source:*
[IAMF\src\IAMF.jl:110](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

---

<a id="method__variables.1" class="lexicon_definition"></a>
#### variables(m::Model, componentname::Symbol) [¶](#method__variables.1)
List all the variables in a component.


*source:*
[IAMF\src\IAMF.jl:51](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

---

<a id="macro___defcomp.1" class="lexicon_definition"></a>
#### @defcomp(name, ex) [¶](#macro___defcomp.1)
Define a new component.


*source:*
[IAMF\src\IAMF.jl:222](file://C:\Users\anthoff\.julia\v0.3\IAMF\src\IAMF.jl)

