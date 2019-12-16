function init_datatable(table) {
  var datatable = new DataTable(table, {
    pageSize: 3,
    sort: [true, true],
    filters: [false, true],
    filterText: 'Type to filter... ',
    pagingDivSelector: "#paging-first-datatable"
  })
}
