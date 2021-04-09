### A Pluto.jl notebook ###
# v0.14.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 3dd53878-9893-11eb-2cc0-b74e03668e27
using LibPQ, PostgresCatalog, FunSQL, PlutoUI

# ╔═╡ 63e4beb0-ece4-4009-9c3c-017be4c3812e
using FunSQL: SQLTable, render, From, Get, Where, Select, Fun

# ╔═╡ 9e7ff019-74fe-4938-baff-89cbf0d5dd0f
using HypertextLiteral: @htl

# ╔═╡ c984eacf-986e-45be-bfa1-7bab2760c678
using HypertextLiteral: @htl_str

# ╔═╡ b945b0d9-b8bd-412e-9626-c54174c670f7
using HypertextLiteral, Dates

# ╔═╡ 3d0791b6-e413-451e-a12b-bbbeacd8fa7f
md"# Customized Record Set Display"

# ╔═╡ d407fb80-d6ff-411e-b92e-871436bd72bc
@htl("""$(@bind selected_person_id Slider(42382:42389, show_value=true))
	<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;show record source?</span>
	$(@bind show_source CheckBox(default=true))
	""")

# ╔═╡ 8302f4a5-cd38-4a1c-bd62-dca7a180c2a7
md"## Querying The OHDSI Database"

# ╔═╡ 455550f4-f26e-494d-9fe6-d01bf3c5e2e3
FunSQL.SQLTable(tbl::PostgresCatalog.PGTable) = SQLTable(Symbol(tbl.name), Symbol[Symbol(col.name) for col in tbl]..., schema=Symbol(tbl.schema.name));

# ╔═╡ 7080c41a-8087-428f-a7d0-c788a1a04e35
conn = LibPQ.Connection("postgresql:///synpuf-5pct?host=/var/run/postgresql");

# ╔═╡ 2f9f894e-4fb2-43a5-affb-dcdcb96f8a94
run(q) = execute(conn, render(q));

# ╔═╡ 1bb7f067-5d57-4719-89f3-ce3a71661b3b
catalog = PostgresCatalog.introspect(conn);

# ╔═╡ baaa2caa-9fac-4888-8cf0-3e86b5addc75
Person = From(SQLTable(catalog["public"]["person"]));

# ╔═╡ 5f25c5fe-ec6e-42bc-82a4-6d95777f6536
Visit = From(SQLTable(catalog["public"]["visit_occurrence"]));

# ╔═╡ 95d32133-2963-4a23-b7e1-93a89eef9162
SelectedPerson = Person |> Where(Fun("=", Get.person_id, selected_person_id)) |> Select([Get.person_id,(show_source ? [Get.person_source_value] : [])..., Get.gender_concept_id, Get.year_of_birth, Get.month_of_birth]...); 

# ╔═╡ e4a46cd9-dee2-462d-9a73-d95f119edb89
Text(render(SelectedPerson))

# ╔═╡ cefdb9b1-a3bb-4576-897f-4914d90db235
SelectedVisits = Visit |> Where(Fun("=", Get.person_id, selected_person_id)) |> Select(Get.person_id, Get.visit_occurrence_id, Get.visit_start_date, Get.visit_end_date, Get.visit_type_concept_id);

# ╔═╡ 1b2e0959-38eb-4e5f-9480-933d2bcc9710
Text(render(SelectedVisits))

# ╔═╡ 80b9977f-13da-4a5d-85e7-28e929ba1eb7
visits = run(SelectedVisits);

# ╔═╡ b4965721-ad8a-4253-af0d-b0d626c9e64c
persons = run(SelectedPerson)

# ╔═╡ 91e020de-97e3-4ec4-80ee-3dee44cc46e6
current_person = collect(persons)[1];

# ╔═╡ 80b3b7a8-df90-4dff-87af-7dbb952e6969
@htl("""
	<table>
	  <caption>Visits for Person #$(current_person.person_id)</caption>
	  <tr><th>person_id<th>visit_occurrence_id
	      <th>visit_start_date<th>visit_end_date</tr>
	  $((@htl("
	  <tr><td>$(row.person_id)<td>$(row.visit_occurrence_id)
	      <td>$(row.visit_start_date)<td>$(row.visit_end_date)</tr>
	  ") for row in visits))
	</table>
""")

# ╔═╡ 9e392d76-9c64-4623-a208-84c29f856847
HTML("""
	<dl>
	  <dt>person_id
	  <dd>42384
	  <dt>gender_concept_id
	  <dd>8507
	</dl>
""")

# ╔═╡ 9f20ba16-cfc6-44d5-b8ec-88eff96e2b79
@htl("""
	<dl>
	  <dt>person_id
	  <dd>$(current_person.person_id)
	  <dt>gender_concept_id
	  <dd>$(current_person.gender_concept_id)
	</dl>	
""")

# ╔═╡ 0bc10936-7d8c-4a61-9d09-30844455f2c9
persons.column_names

# ╔═╡ d0118a9b-98cf-4952-85a7-8766f31b7f4a
template = "<dl>" * join(["<dt>$n<dd>\$(row.$n)" for n in persons.column_names]) * "</dl>"

# ╔═╡ fc08593b-fefa-4bbb-acc2-580f0cbe404c
begin 
	function_changed = show_source;
    eval(:(person_row(row) = @htl_str $template))
end

# ╔═╡ 5d946a84-8a2c-4b9d-a36c-b504ef2d3415
begin 
	function_changed; # cause dynamic update
@htl("""
	<!-- https://www.the-art-of-web.com/css/format-dl/ -->
	<style>
	.simple-dict dl {
      display: flex;
      flex-flow: row wrap;
      border: solid #333;
      border-width: 1px 1px 0 0;
    }
    .simple-dict dt {
      flex-basis: 35%;
      padding: 2px 4px;
      background: #333;
      text-align: right;
      color: #fff;
    }
    .simple-dict dd {
      flex-basis: 50%;
      flex-grow: 1;
      margin: 0;
      padding: 2px 4px;
      border-bottom: 1px solid #333;
    }
	</style>
	<div class=simple-dict>
	  $(person_row(current_person))
	</div>
""")
end

# ╔═╡ da174432-221c-46a4-b56c-a93375e6bd15
person_row(current_person)

# ╔═╡ 2b923ab2-683e-455e-9864-d3c23306a427
HypertextLiteral.content(d::Date) = d

# ╔═╡ 5a327f9d-7a90-425e-8a8a-bea2a0479d3f


# ╔═╡ 8cafcc87-9b02-42c0-ae2b-529a0e5666b1
md"## Custom Object Support"

# ╔═╡ 78f07dbb-4db1-43b9-8296-1d74a69db7a6
begin
	struct MyCustomType
	    data::String
    	style::Any
    end
	MyCustomType(data; kwargs...) = 
	   MyCustomType(data, tuple(kwargs...))
end;

# ╔═╡ 4516f3b9-3554-4637-8db9-f4c3a8a4d9a4
Base.show(io::IO, m::MIME"text/html", c::MyCustomType) =
    show(io, m, @htl("""
		<div>This is... &nbsp;
		   <span style=$(c.style)>$(c.data)</span></div>
	"""))

# ╔═╡ f0f7364d-98df-4200-a278-8b3a66c138ef
MyCustomType("Properly <escaped>")

# ╔═╡ 08f53b21-897b-4584-8ec8-e66282194f6b
MyCustomType("Green & Underlined", 
	text_decoration = :underline, color = :green)

# ╔═╡ Cell order:
# ╟─3d0791b6-e413-451e-a12b-bbbeacd8fa7f
# ╟─5d946a84-8a2c-4b9d-a36c-b504ef2d3415
# ╟─d407fb80-d6ff-411e-b92e-871436bd72bc
# ╠═80b3b7a8-df90-4dff-87af-7dbb952e6969
# ╠═8302f4a5-cd38-4a1c-bd62-dca7a180c2a7
# ╠═3dd53878-9893-11eb-2cc0-b74e03668e27
# ╠═63e4beb0-ece4-4009-9c3c-017be4c3812e
# ╠═455550f4-f26e-494d-9fe6-d01bf3c5e2e3
# ╠═7080c41a-8087-428f-a7d0-c788a1a04e35
# ╠═2f9f894e-4fb2-43a5-affb-dcdcb96f8a94
# ╠═1bb7f067-5d57-4719-89f3-ce3a71661b3b
# ╠═baaa2caa-9fac-4888-8cf0-3e86b5addc75
# ╠═5f25c5fe-ec6e-42bc-82a4-6d95777f6536
# ╠═95d32133-2963-4a23-b7e1-93a89eef9162
# ╟─e4a46cd9-dee2-462d-9a73-d95f119edb89
# ╠═cefdb9b1-a3bb-4576-897f-4914d90db235
# ╟─1b2e0959-38eb-4e5f-9480-933d2bcc9710
# ╠═80b9977f-13da-4a5d-85e7-28e929ba1eb7
# ╠═91e020de-97e3-4ec4-80ee-3dee44cc46e6
# ╠═b4965721-ad8a-4253-af0d-b0d626c9e64c
# ╠═9e392d76-9c64-4623-a208-84c29f856847
# ╠═9e7ff019-74fe-4938-baff-89cbf0d5dd0f
# ╠═9f20ba16-cfc6-44d5-b8ec-88eff96e2b79
# ╠═0bc10936-7d8c-4a61-9d09-30844455f2c9
# ╠═d0118a9b-98cf-4952-85a7-8766f31b7f4a
# ╠═c984eacf-986e-45be-bfa1-7bab2760c678
# ╠═fc08593b-fefa-4bbb-acc2-580f0cbe404c
# ╠═da174432-221c-46a4-b56c-a93375e6bd15
# ╠═b945b0d9-b8bd-412e-9626-c54174c670f7
# ╠═2b923ab2-683e-455e-9864-d3c23306a427
# ╠═5a327f9d-7a90-425e-8a8a-bea2a0479d3f
# ╟─8cafcc87-9b02-42c0-ae2b-529a0e5666b1
# ╠═78f07dbb-4db1-43b9-8296-1d74a69db7a6
# ╠═4516f3b9-3554-4637-8db9-f4c3a8a4d9a4
# ╠═f0f7364d-98df-4200-a278-8b3a66c138ef
# ╠═08f53b21-897b-4584-8ec8-e66282194f6b
