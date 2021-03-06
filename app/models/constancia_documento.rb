class ConstanciaDocumento < ApplicationRecord
  uuidable

  validates :folio, :numero_relacion,
    :numero_oficio, :numero_registro, :codigo_prestatario, :clave_programa,
    :fecha, :nombre, :boleta, :unidad_academica, :programa_academico,
    :periodo, :prestatario, :apellido_paterno, :user_id,
    :apellido_materno, presence: true

  filterrific(
    available_filters: [
      :search_query
    ],
  )

  paginates_per 5

  belongs_to :user

  scope :search_query, lambda { |query|

    # Filtra a los usuarios por nombre o apellido paterno
    return nil  if query.blank?

    # Condiciones del query divididas en palabras separadas y en minúsculas
    terms = query.to_s.downcase.split(/\s+/)

    # Reemplaza "*" con "%" para búsquedas con comodin,
    # liga '%', quita los '%' duplicados
    terms = terms.map { |e|
      (e.gsub('*', '%') + '%').gsub(/%+/, '%')
    }

    # Configura el numero de condiciones OR proporcionados (provision)
    # como argumentos de interpolación. Ajustar si se cambian el
    # número de condiciones OR.
    num_or_conds = 1

    where(
      terms.map { |term|
        "(constancia_documentos.boleta LIKE ?)"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    )
  }

  def to_param
    uuid
  end

  def nombre_completo
    "#{nombre} #{apellido_paterno} #{apellido_materno}"
  end

  def self.formar_cadena(constancia_documento_ids)
    constancia_documentos = ConstanciaDocumento.find(constancia_documento_ids)
    cadenas = []
    constancia_documentos.each do |constancia_documento|
      folio = constancia_documento.folio
      numero_relacion = constancia_documento.numero_relacion
      numero_oficio = constancia_documento.numero_oficio
      numero_registro = constancia_documento.numero_registro
      codigo_prestatario = constancia_documento.codigo_prestatario
      clave_programa = constancia_documento.clave_programa
      fecha = constancia_documento.fecha
      nombre = constancia_documento.nombre
      paterno = constancia_documento.apellido_paterno
      materno = constancia_documento.apellido_materno
      boleta = constancia_documento.boleta
      unidad_academica = constancia_documento.unidad_academica
      programa_academico = constancia_documento.programa_academico
      periodo = constancia_documento.periodo
      prestatario = constancia_documento.prestatario
      cadena = '||' + folio + '|' + numero_relacion + '|' + numero_oficio + '|' +
      numero_registro + '|' + codigo_prestatario + '|' + clave_programa + '|' +
      fecha + '|' + nombre + ' ' + paterno + ' ' + materno + '|' + boleta + '|' + unidad_academica + '|' + programa_academico + '||'
      constancia_documento.update_attributes(firma_departamento: cadena)
      objetos = Hash.new
      objetos["cadena"] = cadena
      objetos["id"] = constancia_documento.id
      cadenas << objetos
    end
    cadenas.to_json
  end

  def self.actualizar_firma(firma_electronica)
    hash_firma = eval(firma_electronica)
    hash_firma[:data][:cadena].each do |x|
      constancia = ConstanciaDocumento.find("#{x[:id]}")
      constancia.update_attributes(firma_direccion: "#{x[:firma]}")
      UserMailer.email_notificacion(constancia).deliver unless constancia.invalid?
    end
  end

end
